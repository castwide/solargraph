describe Solargraph::LanguageServer::Message::TextDocument::Definition do
  it 'finds definitions of methods' do
    host = Solargraph::LanguageServer::Host.new
    host.prepare('spec/fixtures/workspace')
    message = Solargraph::LanguageServer::Message::TextDocument::Definition.new(host, {
      'params' => {
        'textDocument' => {
          'uri' => 'file://spec/fixtures/workspace/lib/other.rb'
        },
        'position' => {
          'line' => 4,
          'character' => 10
        }
      }
    })
    message.process
    expect(message.result.first[:uri]).to eq('file://spec/fixtures/workspace/lib/thing.rb')
  end

  it 'finds definitions of require paths' do
    path = File.absolute_path('spec/fixtures/workspace')
    host = Solargraph::LanguageServer::Host.new
    host.prepare(path)
    message = Solargraph::LanguageServer::Message::TextDocument::Definition.new(host, {
      'params' => {
        'textDocument' => {
          'uri' => "file:///#{path}/lib/other.rb"
        },
        'position' => {
          'line' => 0,
          'character' => 10
        }
      }
    })
    message.process
    expect(message.result.first[:uri]).to eq("file:///#{path}/lib/thing.rb")
  end
end
