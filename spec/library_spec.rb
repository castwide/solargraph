describe Solargraph::Library do
  it "raises an exception for unknown filenames" do
    library = Solargraph::Library.new
    expect {
      library.checkout 'invalid_filename.rb'
    }.to raise_error(Solargraph::Library::FileNotFoundError)
  end

  it "can read a created file" do
    library = Solargraph::Library.new
    library.create('file.rb', 'a = b')
    expect {
      library.checkout 'file.rb'
    }.not_to raise_error
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

  it "deletes a file" do
    library = Solargraph::Library.new
    library.create('file.rb', 'a = b')
    library.delete 'file.rb'
    expect {
      library.checkout 'file.rb'
    }.to raise_error(Solargraph::Library::FileNotFoundError)
  end
end
