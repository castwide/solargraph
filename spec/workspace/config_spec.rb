# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

describe Solargraph::Workspace::Config do
  let(:dir_path) { File.realpath(Dir.mktmpdir) }

  after { FileUtils.remove_entry(dir_path) }

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

  it 'has no type checker rule overrides by default' do
    config = described_class.new(dir_path)
    expect(config.type_checker_rules).to eq({})
  end

  it 'symbolizes a level override for a type checker rule' do
    File.write(File.join(dir_path, '.solargraph.yml'), %(
      type_checker:
        rules:
          validate_calls: typed
    ))
    config = described_class.new(dir_path)
    expect(config.type_checker_rules).to eq(validate_calls: :typed)
  end

  describe '.commented_yaml' do
    it 'renders a doc comment above a key with a CONFIG_DOCS entry' do
      yaml = described_class.commented_yaml('max_files' => 5000)
      expect(yaml).to eq(<<~YAML)
        # Maximum number of files Solargraph will index in this workspace.
        max_files: 5000
      YAML
    end

    it 'renders a key with no CONFIG_DOCS entry without a comment' do
      yaml = described_class.commented_yaml('not_a_real_key' => 'value')
      expect(yaml).to eq("not_a_real_key: value\n")
    end

    it 'round-trips to the same data it was given' do
      conf = described_class.new(dir_path).raw_data
      expect(YAML.safe_load(described_class.commented_yaml(conf))).to eq(conf)
    end
  end
end
