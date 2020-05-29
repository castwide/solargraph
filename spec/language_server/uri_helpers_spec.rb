describe Solargraph::LanguageServer::UriHelpers do
  it "doesn't escapes colons in file paths" do
    file = 'c:/one/two'
    uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(file)
    expect(uri).to start_with('file:///c:')
  end

  it 'uses %20 for spaces' do
    file = '/path/to/a file'
    uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(file)
    expect(uri).to end_with('a%20file')
  end
end
