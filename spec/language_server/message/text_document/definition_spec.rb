describe Solargraph::LanguageServer::Message::TextDocument::Definition do
  it 'prepares empty directory' do
    Dir.mktmpdir do |dir|
      host = Solargraph::LanguageServer::Host.new
      test_rb_path = File.join(dir, 'test.rb')
      thing_rb_path = File.join(dir, 'thing.rb')
      FileUtils.cp('spec/fixtures/workspace/lib/other.rb', test_rb_path)
      FileUtils.cp('spec/fixtures/workspace/lib/thing.rb', thing_rb_path)
      host.prepare(dir)
      sleep 0.1 until host.libraries.all?(&:mapped?)
      host.catalog
      file_uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(test_rb_path)
      other_uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(thing_rb_path)
      message = Solargraph::LanguageServer::Message::TextDocument::Definition
                .new(host, {
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
  end

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

  it 'finds definitions of require paths', time_limit_seconds: 120 do
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
