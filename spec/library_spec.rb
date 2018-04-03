require 'tmpdir'

describe Solargraph::Library do
  it "raises an exception for unknown filenames" do
    library = Solargraph::Library.new
    expect {
      library.checkout 'invalid_filename.rb'
    }.to raise_error(Solargraph::Library::FileNotFoundError)
  end

  it "ignores created files that are not in the workspace" do
    library = Solargraph::Library.new
    result = library.create('file.rb', 'a = b')
    expect(result).to be(false)
    expect {
      library.checkout 'file.rb'
    }.to raise_error(Solargraph::Library::FileNotFoundError)
  end

  it "adds created files when included in the workspace" do
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'file.rb')
      File.write(file, 'a = b')
      library = Solargraph::Library.load(dir)
      result = library.create(file, File.read(file))
      expect(result).to be(true)
      expect {
        library.checkout file
      }.not_to raise_error
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
    }.to raise_error(Solargraph::Library::FileNotFoundError)
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
      }.to raise_error(Solargraph::Library::FileNotFoundError)
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
    }.to raise_error(Solargraph::Library::FileNotFoundError)
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
end
