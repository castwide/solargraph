require 'tmpdir'

describe Solargraph::Workspace do
  it "loads sources from a directory" do
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'file.rb')
      File.write file, 'exit'
      workspace = Solargraph::Workspace.new(dir)
      expect(workspace.filenames).to include(file)
    end
  end

  it "ignores non-Ruby files by default" do
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'file.rb')
      File.write file, 'exit'
      not_ruby = File.join(dir, 'not_ruby.txt')
      File.write not_ruby, 'text'
      workspace = Solargraph::Workspace.new(dir)
      expect(workspace.filenames).to include(file)
      expect(workspace.filenames).not_to include(not_ruby)
    end
  end

  it "does not merge non-workspace sources" do
    Dir.mktmpdir do |dir|
      workspace = Solargraph::Workspace.new(dir)
      source = Solargraph::Source.load_string('exit', 'not_ruby.txt')
      workspace.merge source
      expect(workspace.filenames).not_to include(source.filename)
    end
  end

  it "updates sources" do
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'file.rb')
      File.write file, 'exit'
      workspace = Solargraph::Workspace.new(dir)
      original = workspace.source(file)
      updated = Solargraph::Source.load_string('puts "updated"', file)
      workspace.merge updated
      expect(workspace.filenames).to include(file)
      expect(workspace.source(file)).not_to eq(original)
      expect(workspace.source(file)).to eq(updated)
    end
  end

  it "removes deleted sources" do
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'file.rb')
      File.write file, 'exit'
      workspace = Solargraph::Workspace.new(dir)
      expect(workspace.filenames).to include(file)
      original = workspace.source(file)
      File.unlink file
      workspace.remove original
      expect(workspace.filenames).not_to include(file)
    end
  end
end
