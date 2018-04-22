require 'tmpdir'

describe Solargraph::Workspace::Config do
  let(:config) { described_class.new(workspace_path) }
  let(:workspace_path) { Dir.mktmpdir }

  after(:each) { FileUtils.remove_entry(workspace_path) }

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
end
