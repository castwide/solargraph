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

  it 'rejects a value that should be an array of strings' do
    File.open(File.join(dir_path, '.solargraph.yml'), 'w') do |file|
      file.puts 'domains: not_an_array'
    end
    config = described_class.new(dir_path)
    expect { config.domains }.to raise_error(Solargraph::InvalidConfigError, /domains/)
  end

  it 'falls back to an empty array when a value is explicitly nil' do
    File.open(File.join(dir_path, '.solargraph.yml'), 'w') do |file|
      file.puts 'plugins:'
    end
    config = described_class.new(dir_path)
    expect(config.plugins).to eq([])
  end

  it 'rejects a max_files value that is not an integer' do
    File.open(File.join(dir_path, '.solargraph.yml'), 'w') do |file|
      file.puts 'max_files: not_an_integer'
    end
    config = described_class.new(dir_path)
    expect { config.max_files }.to raise_error(Solargraph::InvalidConfigError, /max_files/)
  end

  it 'rejects a formatter value that is not a hash' do
    File.open(File.join(dir_path, '.solargraph.yml'), 'w') do |file|
      file.puts 'formatter: not_a_hash'
    end
    config = described_class.new(dir_path)
    expect { config.formatter }.to raise_error(Solargraph::InvalidConfigError, /formatter/)
  end
end
