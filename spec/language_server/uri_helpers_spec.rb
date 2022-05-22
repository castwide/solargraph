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

  it 'removes file:// prefix' do
    uri = 'file:///dev_tools/'
    file = Solargraph::LanguageServer::UriHelpers.uri_to_file(uri)
    expect(file).to eq('/dev_tools/')
  end

  it 'removes file: prefix' do
    uri = 'file:/dev_tools/'
    file = Solargraph::LanguageServer::UriHelpers.uri_to_file(uri)
    expect(file).to eq('/dev_tools/')
  end

  it 'removes file:/// prefix when a drive is specified' do
    uri = 'file:///Z:/dev_tools/'
    file = Solargraph::LanguageServer::UriHelpers.uri_to_file(uri)
    expect(file).to eq('Z:/dev_tools/')
  end

  it 'removes file:/ prefix when a drive is specified' do
    uri = 'file:/Z:/dev_tools/'
    file = Solargraph::LanguageServer::UriHelpers.uri_to_file(uri)
    expect(file).to eq('Z:/dev_tools/')
  end
end
