describe Solargraph::Library do
  it "raises an exception for unknown filenames" do
    library = Solargraph::Library.new
    expect {
      library.checkout 'invalid_filename.rb'
    }.to raise_error(Solargraph::Library::FileNotFoundError)
  end
end
