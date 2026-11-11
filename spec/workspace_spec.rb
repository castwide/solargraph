# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

describe Solargraph::Workspace do
  let(:workspace) { described_class.new(dir_path) }
  let(:dir_path)  { File.realpath(Dir.mktmpdir) }
  let(:file_path) { File.join(dir_path, 'file.rb') }

  before   { File.write(file_path, 'exit') }
  after    { FileUtils.remove_entry(dir_path) }

  it 'loads sources from a directory' do
    expect(workspace.filenames).to include(file_path)
    expect(workspace.has_file?(file_path)).to be(true)
  end

  it 'ignores non-Ruby files by default' do
    not_ruby = File.join(dir_path, 'not_ruby.txt')
    File.write not_ruby, 'text'

    expect(workspace.filenames).to include(file_path)
    expect(workspace.filenames).not_to include(not_ruby)
  end

  it 'does not merge non-workspace sources' do
    source = Solargraph::Source.load_string('exit', 'not_ruby.txt')
    workspace.merge source

    expect(workspace.filenames).not_to include(source.filename)
  end

  it 'updates sources' do
    original = workspace.source(file_path)
    updated = Solargraph::Source.load_string('puts "updated"', file_path)
    workspace.merge updated

    expect(workspace.filenames).to include(file_path)
    expect(workspace.source(file_path)).not_to eq(original)
    expect(workspace.source(file_path)).to eq(updated)
  end

  it 'removes deleted sources' do
    expect(workspace.filenames).to include(file_path)

    original = workspace.source(file_path)
    File.unlink file_path
    workspace.remove original.filename

    expect(workspace.filenames).not_to include(file_path)
  end

  it 'raises an exception for workspace size limits' do
    config = instance_double(Solargraph::Workspace::Config,
                             calculated: Array.new(Solargraph::Workspace::Config::MAX_FILES + 1), max_files: Solargraph::Workspace::Config::MAX_FILES)

    expect do
      described_class.new('.', config)
    end.to raise_error(Solargraph::WorkspaceTooLargeError)
  end

  it 'allows for unlimited files in config' do
    gemspec_file = File.join(dir_path, 'test.gemspec')
    File.write(gemspec_file, '')
    calculated = Array.new(Solargraph::Workspace::Config::MAX_FILES + 1) { gemspec_file }
    # @todo Mock reveals tight coupling
    config = instance_double(Solargraph::Workspace::Config, calculated: calculated, max_files: 0, allow?: true,
                                                            require_paths: [], plugins: [])
    expect do
      described_class.new('.', config)
    end.not_to raise_error
  end

  it 'detects gemspecs in workspaces' do
    gemspec_file = File.join(dir_path, 'test.gemspec')
    File.write(gemspec_file, '')
    expect(workspace.gemspec?).to be(true)
    expect(workspace.gemspec_files).to eq([gemspec_file])
  end

  it 'generates default require path' do
    expect(workspace.require_paths).to eq([File.join(dir_path, 'lib')])
  end

  it 'generates require paths from gemspecs' do
    gemspec_file = File.join(dir_path, 'test.gemspec')
    File.write(gemspec_file, %(
      Gem::Specification.new do |s|
        s.files = []
        s.name = 'Workspace test'
        s.summary = 'A test of workspace gemspec processing'
        s.version = '0.0.1'
        s.require_paths = ['other_lib']
      end
    ))
    expect(workspace.require_paths).to eq([File.join(dir_path, 'other_lib')])
  end

  it 'rescues errors in gemspecs' do
    gemspec_file = File.join(dir_path, 'test.gemspec')
    File.write(gemspec_file, %(
      raise 'Error'
    ))
    expect(workspace.require_paths).to eq([File.join(dir_path, 'lib')])
  end

  it 'rescues syntax errors in gemspecs' do
    gemspec_file = File.join(dir_path, 'test.gemspec')
    File.write(gemspec_file, %(
      123.
    ))
    expect(workspace.require_paths).to eq([File.join(dir_path, 'lib')])
  end

  it 'detects locally required paths' do
    required_file = File.join(dir_path, 'lib', 'test.rb')
    Dir.mkdir(File.join(dir_path, 'lib'))
    File.write(required_file, 'exit')
    expect(workspace.would_require?('test')).to be(true)
    expect(workspace.would_require?('not_there')).to be(false)
  end

  it 'would not require directory paths' do
    FileUtils.mkdir_p(File.join(dir_path, 'lib', 'emptydir'))
    expect(workspace.would_require?('emptydir')).to be(false)
  end

  it 'uses configured require paths' do
    workspace = described_class.new('spec/fixtures/workspace')
    expect(workspace.require_paths).to eq([File.absolute_path('spec/fixtures/workspace/lib'),
                                           File.absolute_path('spec/fixtures/workspace/ext')])
  end

  it 'ignores gemspecs in excluded directories' do
    # vendor/**/* is excluded by default
    workspace = described_class.new('spec/fixtures/vendored')
    expect(workspace.require_paths).to eq([File.absolute_path('spec/fixtures/vendored/lib')])
  end

  it 'rescues errors loading files into sources' do
    config = instance_double(Solargraph::Workspace::Config, directory: './path',
                                                            calculated: ['./path/does_not_exist.rb'], max_files: 5000, require_paths: [], plugins: [])
    expect do
      described_class.new('./path', config)
    end.not_to raise_error
  end

  context 'with two workspaces, one with a plugin configured' do
    # Holds the plugin's load path, the workspace without plugins and a gem
    let(:scratch_dir) { File.realpath(Dir.mktmpdir) }
    let(:metagem) do
      Solargraph::Metagem.new(name: 'workspace_probe_gem', full_path: File.join(scratch_dir, 'workspace_probe_gem-1.0.0'),
                              spec_file: '', source: 'rubygems repository', version: '1.0.0',
                              require_paths: ['lib'], dependencies: [])
    end

    before do
      FileUtils.mkdir_p [File.join(scratch_dir, 'plugins'), File.join(scratch_dir, 'plain'), File.join(metagem.full_path, 'lib')]
      File.write(File.join(scratch_dir, 'plugins', 'workspace_probe_plugin.rb'), '')
      File.write(File.join(dir_path, '.solargraph.yml'), "plugins:\n  - workspace_probe_plugin\n")
      File.write(File.join(metagem.full_path, 'lib', 'workspace_probe_gem.rb'), 'module WorkspaceProbeGem; end')
      $LOAD_PATH.unshift File.join(scratch_dir, 'plugins')
    end

    after do
      $LOAD_PATH.delete File.join(scratch_dir, 'plugins')
      $LOADED_FEATURES.delete_if { |path| path.end_with?('workspace_probe_plugin.rb') }
      FileUtils.rm_rf scratch_dir
    end

    it 'keeps the plain gem directory after loading the plugin workspace' do
      described_class.new(dir_path)
      expect(Solargraph::CacheDir.gem_dir).to eq(File.join(Solargraph::CacheDir.work_dir, 'gems'))
    end

    it 'caches and reads gems in each workspace\'s own directory' do
      with_plugin = described_class.new(dir_path)
      without_plugin = described_class.new(File.join(scratch_dir, 'plain'))
      Solargraph::Collection::Gem.load metagem, with_plugin.plugin_versions
      expect(Solargraph::Collection::Gem.cached?(metagem, without_plugin.plugin_versions)).to be(false)

      Solargraph::Collection::Gem.load metagem, without_plugin.plugin_versions
      cache_dirs = [with_plugin, without_plugin].map do |workspace|
        File.dirname(Solargraph::Collection::Gem.new(metagem, workspace.plugin_versions).cache_file)
      end
      expect(cache_dirs).to eq([Solargraph::CacheDir.gem_dir('workspace_probe_plugin' => nil),
                                File.join(Solargraph::CacheDir.work_dir, 'gems')])
    ensure
      [with_plugin, without_plugin].compact.each { |workspace| Solargraph::Collection::Gem.uncache metagem, workspace.plugin_versions }
    end

    it 'passes its plugins to the ApiMap that catalogs it' do
      api_map = Solargraph::ApiMap.new
      api_map.catalog Solargraph::Bench.new(workspace: described_class.new(dir_path))
      expect(api_map.external.plugin_versions.keys).to eq(['workspace_probe_plugin'])
    end
  end
end
