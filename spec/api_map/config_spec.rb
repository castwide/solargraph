require 'tmpdir'

describe Solargraph::Workspace::Config do
  let(:config) { described_class.new(workspace_path) }
  let(:workspace_path) { File.realpath(Dir.mktmpdir) }
  let(:global_path) { @global_path }

  before(:each) do
    @global_path = File.realpath(Dir.mktmpdir)
    @orig_env = ENV['SOLARGRAPH_GLOBAL_CONFIG']
    ENV['SOLARGRAPH_GLOBAL_CONFIG'] = File.join(@global_path, '.solargraph.yml')
  end

  after(:each) do
    ENV['SOLARGRAPH_GLOBAL_CONFIG'] = @orig_env
    FileUtils.remove_entry(workspace_path)
    FileUtils.remove_entry(global_path)
  end

  it "reads workspace files from config" do
    File.write(File.join(workspace_path, 'foo.rb'), 'test')
    File.write(File.join(workspace_path, 'bar.rb'), 'test')
    File.open(File.join(workspace_path, '.solargraph.yml'), 'w') do |file|
      file.puts "include:"
      file.puts "  - foo.rb"
      file.puts "exclude:"
      file.puts "  - bar.rb"
    end

    expect(config.included).to eq([File.join(workspace_path, 'foo.rb')])
    expect(config.excluded).to eq([File.join(workspace_path, 'bar.rb')])
  end

  it "reads workspace files from global config" do
    File.write(File.join(workspace_path, 'foo.rb'), 'test')
    File.write(File.join(workspace_path, 'bar.rb'), 'test')

    File.open(File.join(global_path, '.solargraph.yml'), 'w') do |file|
      file.puts "include:"
      file.puts "  - foo.rb"
      file.puts "exclude:"
      file.puts "  - bar.rb"
    end

    expect(config.included).to eq([File.join(workspace_path, 'foo.rb')])
    expect(config.excluded).to eq([File.join(workspace_path, 'bar.rb')])
  end

  it "overrides global config with workspace config" do
    File.write(File.join(workspace_path, 'foo.rb'), 'test')
    File.write(File.join(workspace_path, 'bar.rb'), 'test')
    
    File.open(File.join(workspace_path, '.solargraph.yml'), 'w') do |file|
        file.puts "include:"
        file.puts "  - foo.rb"
        file.puts "max_files: 8000"
    end
    File.open(File.join(global_path, '.solargraph.yml'), 'w') do |file|
      file.puts "include:"
      file.puts "  - include.rb"
      file.puts "exclude:"
      file.puts "  - bar.rb"
      file.puts "max_files: 1000"
    end

    expect(config.included).to eq([File.join(workspace_path, 'foo.rb')])
    expect(config.excluded).to eq([File.join(workspace_path, 'bar.rb')])
    expect(config.max_files).to eq(8000)
  end
end
