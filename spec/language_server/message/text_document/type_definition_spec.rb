describe Solargraph::LanguageServer::Message::TextDocument::TypeDefinition do
  it 'finds definitions of methods' do
    host = Solargraph::LanguageServer::Host.new
    host.prepare('spec/fixtures/workspace')
    sleep 0.1 until host.libraries.all?(&:mapped?)
    host.catalog
    file_uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(File.absolute_path('spec/fixtures/workspace/lib/other.rb'))
    something_uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(File.absolute_path('spec/fixtures/workspace/lib/something.rb'))
    message = Solargraph::LanguageServer::Message::TextDocument::TypeDefinition.new(host, {
      'params' => {
        'textDocument' => {
          'uri' => file_uri
        },
        'position' => {
          'line' => 4,
          'character' => 10
        }
      }
    })
    message.process
    expect(message.result.first[:uri]).to eq(something_uri)
  end
end
