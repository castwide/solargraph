require 'tmpdir'

describe Solargraph::Workspace::Config do
  it "reads workspace files from config" do
    Dir.mktmpdir do |dir|
      File.open(File.join(dir, 'foo.rb'), 'w') do |file|
        file << 'test'
      end
      File.open(File.join(dir, 'bar.rb'), 'w') do |file|
        file << 'test'
      end
      File.open(File.join(dir, '.solargraph.yml'), 'w') do |file|
        file.puts "include:"
        file.puts "  - foo.rb"
        file.puts "exclude:"
        file.puts "  - bar.rb"
      end
      config = Solargraph::Workspace::Config.new(dir)
      expect(config.included).to eq([File.join(dir, 'foo.rb')])
      expect(config.excluded).to eq([File.join(dir, 'bar.rb')])
    end
  end
end
