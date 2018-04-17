require 'tmpdir'

describe Solargraph::Workspace do
  let(:dir_path) { Dir.mktmpdir }
  after(:each) { FileUtils.remove_entry(dir_path) }

  it "loads sources from a directory" do
    file = File.join(dir_path, 'file.rb')
    File.write file, 'exit'
    workspace = Solargraph::Workspace.new(dir_path)
    expect(workspace.filenames).to include(file)
    expect(workspace.has_file?(file)).to be(true)
  end

  it "ignores non-Ruby files by default" do
    file = File.join(dir_path, 'file.rb')
    File.write file, 'exit'
    not_ruby = File.join(dir_path, 'not_ruby.txt')
    File.write not_ruby, 'text'
    workspace = Solargraph::Workspace.new(dir_path)
    expect(workspace.filenames).to include(file)
    expect(workspace.filenames).not_to include(not_ruby)
  end

  it "does not merge non-workspace sources" do
    workspace = Solargraph::Workspace.new(dir_path)
    source = Solargraph::Source.load_string('exit', 'not_ruby.txt')
    workspace.merge source
    expect(workspace.filenames).not_to include(source.filename)
  end

  it "updates sources" do
    file = File.join(dir_path, 'file.rb')
    File.write file, 'exit'
    workspace = Solargraph::Workspace.new(dir_path)
    original = workspace.source(file)
    updated = Solargraph::Source.load_string('puts "updated"', file)
    workspace.merge updated
    expect(workspace.filenames).to include(file)
    expect(workspace.source(file)).not_to eq(original)
    expect(workspace.source(file)).to eq(updated)
  end

  it "removes deleted sources" do
    file = File.join(dir_path, 'file.rb')
    File.write file, 'exit'
    workspace = Solargraph::Workspace.new(dir_path)
    expect(workspace.filenames).to include(file)
    original = workspace.source(file)
    File.unlink file
    workspace.remove original
    expect(workspace.filenames).not_to include(file)
  end

  it "raises an exception for workspace size limits" do
    config = double
    allow(config).to receive(:calculated).and_return(Array.new(Solargraph::Workspace::MAX_WORKSPACE_SIZE + 1))
    expect {
      workspace = Solargraph::Workspace.new('.', config)
    }.to raise_error(Solargraph::WorkspaceTooLargeError)
  end
end
