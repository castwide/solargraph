require 'tmpdir'

describe Solargraph::Library do
  it "raises an exception for unknown filenames" do
    library = Solargraph::Library.new
    expect {
      library.checkout 'invalid_filename.rb'
    }.to raise_error(Solargraph::FileNotFoundError)
  end

  it "ignores created files that are not in the workspace" do
    library = Solargraph::Library.new
    result = library.create('file.rb', 'a = b')
    expect(result).to be(false)
    expect {
      library.checkout 'file.rb'
    }.to raise_error(Solargraph::FileNotFoundError)
  end

  it "does not open created files in the workspace" do
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'file.rb')
      File.write(file, 'a = b')
      library = Solargraph::Library.load(dir)
      result = library.create(file, File.read(file))
      expect(result).to be(true)
      expect {
        library.checkout file
      }.to raise_error(Solargraph::FileNotFoundError)
    end
  end

  it "opens a file" do
    library = Solargraph::Library.new
    library.open('file.rb', 'a = b', 0)
    source = nil
    expect {
      source = library.checkout('file.rb')
    }.not_to raise_error
    expect(source.filename).to eq('file.rb')
  end

  it "deletes an open file" do
    library = Solargraph::Library.new
    library.open('file.rb', 'a = b', 0)
    library.delete 'file.rb'
    expect {
      library.checkout 'file.rb'
    }.to raise_error(Solargraph::FileNotFoundError)
  end

  it "deletes a file from the workspace" do
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'file.rb')
      File.write(file, 'a = b')
      library = Solargraph::Library.load(dir)
      library.open file, File.read(file), 0
      expect {
        library.checkout file
      }.not_to raise_error
      File.unlink file
      library.delete file
      expect {
        library.checkout file
      }.to raise_error(Solargraph::FileNotFoundError)
    end
  end

  it "makes a closed file unavailable" do
    library = Solargraph::Library.new
    library.open 'file.rb', 'a = b', 0
    expect {
      library.checkout 'file.rb'
    }.not_to raise_error
    library.close 'file.rb'
    expect {
      library.checkout 'file.rb'
    }.to raise_error(Solargraph::FileNotFoundError)
  end

  it "returns a Completion" do
    library = Solargraph::Library.new
    library.open 'file.rb', %(
      x = 1
      x
    ), 0
    library.checkout 'file.rb'
    completion = library.completions_at('file.rb', 2, 7)
    expect(completion.class).to be(Solargraph::ApiMap::Completion)
    expect(completion.pins.map(&:name)).to include('x')
  end

  it "gets definitions from a file" do
    library = Solargraph::Library.new
    library.open 'file.rb', %(
      class Foo
        def bar
        end
      end
    ), 0
    library.checkout 'file.rb'
    paths = library.definitions_at('file.rb', 2, 13).map(&:path)
    expect(paths).to include('Foo#bar')
  end

  it "ignores invalid filenames in create_from_disk" do
    library = Solargraph::Library.new
    filename = 'not_a_real_file.rb'
    expect(library.create_from_disk(filename)).to be(false)
    expect(library.contain?(filename)).to be(false)
  end

  it "adds mergeable files to the workspace in create_from_disk" do
    Dir.mktmpdir do |dir|
      library = Solargraph::Library.load(dir)
      filename = File.join(dir, 'created.rb')
      File.write(filename, "puts 'hello'")
      expect(library.create_from_disk(filename)).to be(true)
      expect(library.contain?(filename)).to be(true)
    end
  end

  it "ignores non-mergeable files in create_from_disk" do
    Dir.mktmpdir do |dir|
      library = Solargraph::Library.load(dir)
      filename = File.join(dir, 'created.txt')
      File.write(filename, "puts 'hello'")
      expect(library.create_from_disk(filename)).to be(false)
      expect(library.contain?(filename)).to be(false)
    end
  end
end
