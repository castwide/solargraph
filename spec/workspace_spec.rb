require 'fileutils'
require 'tmpdir'

describe Solargraph::Workspace do
  let(:workspace) { described_class.new(dir_path) }
  let(:dir_path)  { File.realpath(Dir.mktmpdir) }
  let(:file_path) { File.join(dir_path, 'file.rb') }

  before(:each)   { File.write(file_path, 'exit') }
  after(:each)    { FileUtils.remove_entry(dir_path) }

  it "loads sources from a directory" do
    expect(workspace.filenames).to include(file_path)
    expect(workspace.has_file?(file_path)).to be(true)
  end

  it "ignores non-Ruby files by default" do
    not_ruby = File.join(dir_path, 'not_ruby.txt')
    File.write not_ruby, 'text'

    expect(workspace.filenames).to include(file_path)
    expect(workspace.filenames).not_to include(not_ruby)
  end

  it "does not merge non-workspace sources" do
    source = Solargraph::Source.load_string('exit', 'not_ruby.txt')
    workspace.merge source

    expect(workspace.filenames).not_to include(source.filename)
  end

  it "updates sources" do
    original = workspace.source(file_path)
    updated = Solargraph::Source.load_string('puts "updated"', file_path)
    workspace.merge updated

    expect(workspace.filenames).to include(file_path)
    expect(workspace.source(file_path)).not_to eq(original)
    expect(workspace.source(file_path)).to eq(updated)
  end

  it "removes deleted sources" do
    expect(workspace.filenames).to include(file_path)

    original = workspace.source(file_path)
    File.unlink file_path
    workspace.remove original.filename

    expect(workspace.filenames).not_to include(file_path)
  end

  it "raises an exception for workspace size limits" do
    config = double(:config, calculated: Array.new(Solargraph::Workspace::Config::MAX_FILES + 1), max_files: Solargraph::Workspace::Config::MAX_FILES)

    expect {
      Solargraph::Workspace.new('.', config)
    }.to raise_error(Solargraph::WorkspaceTooLargeError)
  end

  it "allows for unlimited files in config" do
    gemspec_file = File.join(dir_path, 'test.gemspec')
    File.write(gemspec_file, '')
    calculated = Array.new(Solargraph::Workspace::Config::MAX_FILES + 1) { gemspec_file }
    # @todo Mock reveals tight coupling
    config = double(:config, calculated: calculated, max_files: 0, allow?: true, require_paths: [], plugins: [])
    expect {
      Solargraph::Workspace.new('.', config)
    }.not_to raise_error
  end

  it "detects gemspecs in workspaces" do
    gemspec_file = File.join(dir_path, 'test.gemspec')
    File.write(gemspec_file, '')
    expect(workspace.gemspec?).to be(true)
    expect(workspace.gemspecs).to eq([gemspec_file])
  end

  it "generates default require path" do
    expect(workspace.require_paths).to eq([File.join(dir_path, 'lib')])
  end

  it "generates require paths from gemspecs" do
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

  it "rescues errors in gemspecs" do
    gemspec_file = File.join(dir_path, 'test.gemspec')
    File.write(gemspec_file, %(
      raise 'Error'
    ))
    expect(workspace.require_paths).to eq([File.join(dir_path, 'lib')])
  end

  it "rescues syntax errors in gemspecs" do
    gemspec_file = File.join(dir_path, 'test.gemspec')
    File.write(gemspec_file, %(
      123.
    ))
    expect(workspace.require_paths).to eq([File.join(dir_path, 'lib')])
  end

  it "detects locally required paths" do
    required_file = File.join(dir_path, 'lib', 'test.rb')
    Dir.mkdir(File.join(dir_path, 'lib'))
    File.write(required_file, 'exit')
    expect(workspace.would_require?('test')).to be(true)
    expect(workspace.would_require?('not_there')).to be(false)
  end

  it "uses configured require paths" do
    workspace = Solargraph::Workspace.new('spec/fixtures/workspace')
    expect(workspace.require_paths).to eq(['spec/fixtures/workspace/lib', 'spec/fixtures/workspace/ext'])
  end

  it 'ignores gemspecs in excluded directories' do
    # vendor/**/* is excluded by default
    workspace = Solargraph::Workspace.new('spec/fixtures/vendored')
    expect(workspace.gemspecs).to be_empty
  end

  it 'rescues errors loading files into sources' do
    config = double(:Config, directory: './path', calculated: ['./path/does_not_exist.rb'], max_files: 5000, require_paths: [], plugins: [])
    expect {
      Solargraph::Workspace.new('./path', config)
    }.not_to raise_error
  end
end
