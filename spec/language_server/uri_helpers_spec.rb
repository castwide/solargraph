describe Solargraph::LanguageServer::UriHelpers do
  it "don't escapes colons in file paths" do
    file = "c:/one/two"
    uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(file)
    expect(uri).to start_with('file:///c:')
  end
end
