describe Solargraph::LanguageServer::Message::TextDocument::Definition do
  it 'finds definitions of methods' do
    host = Solargraph::LanguageServer::Host.new
    host.prepare('spec/fixtures/workspace')
    sleep 0.1 until host.libraries.all?(&:mapped?)
    host.catalog
    file_uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(File.absolute_path('spec/fixtures/workspace/lib/other.rb'))
    other_uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(File.absolute_path('spec/fixtures/workspace/lib/thing.rb'))
    message = Solargraph::LanguageServer::Message::TextDocument::Definition.new(host, {
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
    expect(message.result.first[:uri]).to eq(other_uri)
  end

  it 'finds definitions of require paths' do
    path = File.absolute_path('spec/fixtures/workspace')
    host = Solargraph::LanguageServer::Host.new
    host.prepare(path)
    sleep 0.1 until host.libraries.all?(&:mapped?)
    host.catalog
    message = Solargraph::LanguageServer::Message::TextDocument::Definition.new(host, {
      'params' => {
        'textDocument' => {
          'uri' => Solargraph::LanguageServer::UriHelpers.file_to_uri(File.join(path, 'lib', 'other.rb'))
        },
        'position' => {
          'line' => 0,
          'character' => 10
        }
      }
    })
    message.process
    expect(message.result.first[:uri]).to eq(Solargraph::LanguageServer::UriHelpers.file_to_uri(File.join(path, 'lib', 'thing.rb')))
  end
end
