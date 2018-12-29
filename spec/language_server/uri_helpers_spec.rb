describe Solargraph::LanguageServer::UriHelpers do
  it "escapes colons in file paths" do
    file = "c:/one/two"
    uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(file)
    expect(uri).to start_with('file:///c%3A')
  end
end
