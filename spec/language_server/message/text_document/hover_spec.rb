describe Solargraph::LanguageServer::Message::TextDocument::Hover do
  it 'returns nil for empty documentation' do
    host = Solargraph::LanguageServer::Host.new
    host.prepare('spec/fixtures/workspace')
    sleep 0.1 until host.libraries.all?(&:mapped?)
    host.catalog
    message = Solargraph::LanguageServer::Message::TextDocument::Hover.new(host, {
      'params' => {
        'textDocument' => {
          'uri' => 'file://spec/fixtures/workspace/lib/other.rb'
        },
        'position' => {
          'line' => 5,
          'character' => 0
        }
      }
    })
    message.process
    expect(message.result[:contents][:value]).to be_nil
  end
end
