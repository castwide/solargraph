describe Solargraph::LanguageServer::Message::TextDocument::Formatting do
  it 'gracefully handles empty files' do
    host = double(:Host, read_text: '', formatter_config: {})
    request = {
      'params' => {
          'textDocument' => {
          'uri' => 'test.rb'
        }
      }
    }
    message = Solargraph::LanguageServer::Message::TextDocument::Formatting.new(host, request)
    message.process
    expect(message.process.first[:newText]).to be_empty
  end
end
