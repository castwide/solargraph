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
    workspace.remove original

    expect(workspace.filenames).not_to include(file_path)
  end

  it "raises an exception for workspace size limits" do
    config = double(:config, calculated: Array.new(Solargraph::Workspace::MAX_WORKSPACE_SIZE + 1))

    expect {
      Solargraph::Workspace.new('.', config)
    }.to raise_error(Solargraph::WorkspaceTooLargeError)
  end
end
