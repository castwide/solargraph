require 'fileutils'
require 'tmpdir'

describe Solargraph::Workspace::Config do
  let(:dir_path)  { File.realpath(Dir.mktmpdir) }
  after(:each)    { FileUtils.remove_entry(dir_path) }

  it "includes .rb files by default" do
    file = File.join(dir_path, 'file.rb')
    File.write(file, 'exit')
    config = Solargraph::Workspace::Config.new(dir_path)
    expect(config.calculated).to include(file)
  end

  it "includes .rb files in subdirectories by default" do
    Dir.mkdir(File.join(dir_path, 'lib'))
    file = File.join(dir_path, 'lib', 'file.rb')
    File.write(file, 'exit')
    config = Solargraph::Workspace::Config.new(dir_path)
    expect(config.calculated).to include(file)
  end

  it "excludes test directories by default" do
    Dir.mkdir(File.join(dir_path, 'test'))
    file = File.join(dir_path, 'test', 'file.rb')
    File.write(file, 'exit')
    config = Solargraph::Workspace::Config.new(dir_path)
    expect(config.calculated).not_to include(file)
  end

  it "excludes spec directories by default" do
    Dir.mkdir(File.join(dir_path, 'spec'))
    file = File.join(dir_path, 'spec', 'file.rb')
    File.write(file, 'exit')
    config = Solargraph::Workspace::Config.new(dir_path)
    expect(config.calculated).not_to include(file)
  end

  it "excludes vendor directories by default" do
    Dir.mkdir(File.join(dir_path, 'vendor'))
    file = File.join(dir_path, 'vendor', 'file.rb')
    File.write(file, 'exit')
    config = Solargraph::Workspace::Config.new(dir_path)
    expect(config.calculated).not_to include(file)
  end
end
