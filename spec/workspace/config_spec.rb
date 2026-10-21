# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

describe Solargraph::Workspace::Config do
  let(:dir_path) { File.realpath(Dir.mktmpdir) }

  after { FileUtils.remove_entry(dir_path) }

  describe '#require_plugins' do
    before do
      File.write(File.join(dir_path, 'config_probe_plugin.rb'), '')
      File.write(File.join(dir_path, '.solargraph.yml'), "plugins:\n  - config_probe_plugin\n  - missing_probe_plugin\n")
      $LOAD_PATH.unshift dir_path
    end

    after do
      $LOAD_PATH.delete dir_path
      $LOADED_FEATURES.delete_if { |path| path.end_with?('config_probe_plugin.rb') }
      Solargraph::CacheDir.plugins.delete 'config_probe_plugin'
    end

    it 'records the plugins it loads in the gem cache key' do
      described_class.new(dir_path).require_plugins
      expect(Solargraph::CacheDir.plugins.keys).to include('config_probe_plugin')
    end

    it 'leaves plugins that fail to load out of the gem cache key' do
      described_class.new(dir_path).require_plugins
      expect(Solargraph::CacheDir.plugins.keys).not_to include('missing_probe_plugin')
    end
  end

  it 'includes .rb files by default' do
    file = File.join(dir_path, 'file.rb')
    File.write(file, 'exit')
    config = described_class.new(dir_path)
    expect(config.calculated).to include(file)
  end

  it 'includes .rb files in subdirectories by default' do
    Dir.mkdir(File.join(dir_path, 'lib'))
    file = File.join(dir_path, 'lib', 'file.rb')
    File.write(file, 'exit')
    config = described_class.new(dir_path)
    expect(config.calculated).to include(file)
  end

  it 'excludes test directories by default' do
    Dir.mkdir(File.join(dir_path, 'test'))
    file = File.join(dir_path, 'test', 'file.rb')
    File.write(file, 'exit')
    config = described_class.new(dir_path)
    expect(config.calculated).not_to include(file)
  end

  it 'excludes spec directories by default' do
    Dir.mkdir(File.join(dir_path, 'spec'))
    file = File.join(dir_path, 'spec', 'file.rb')
    File.write(file, 'exit')
    config = described_class.new(dir_path)
    expect(config.calculated).not_to include(file)
  end

  it 'excludes vendor directories by default' do
    Dir.mkdir(File.join(dir_path, 'vendor'))
    file = File.join(dir_path, 'vendor', 'file.rb')
    File.write(file, 'exit')
    config = described_class.new(dir_path)
    expect(config.calculated).not_to include(file)
  end

  it 'includes base reporters by default' do
    config = described_class.new(dir_path)
    expect(config.reporters).to include('rubocop')
    expect(config.reporters).to include('require_not_found')
  end
end
