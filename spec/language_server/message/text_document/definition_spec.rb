# frozen_string_literal: true

require 'timeout'

describe Solargraph::LanguageServer::Message::TextDocument::Definition do
  it 'prepares empty directory' do
    Dir.mktmpdir do |dir|
      host = Solargraph::LanguageServer::Host.new
      test_rb_path = File.join(dir, 'test.rb')
      thing_rb_path = File.join(dir, 'thing.rb')
      FileUtils.cp('spec/fixtures/workspace/lib/other.rb', test_rb_path)
      FileUtils.cp('spec/fixtures/workspace/lib/thing.rb', thing_rb_path)
      host.prepare(dir)
      Timeout.timeout 60 do
        sleep 0.1 until host.libraries.all?(&:mapped?)
      end
      host.catalog
      file_uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(test_rb_path)
      other_uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(thing_rb_path)
      message = described_class
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
    Timeout.timeout 60 do
      sleep 0.1 until host.libraries.all?(&:mapped?)
    end
    host.catalog
    file_uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(File.absolute_path('spec/fixtures/workspace/lib/other.rb'))
    other_uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(File.absolute_path('spec/fixtures/workspace/lib/thing.rb'))
    message = described_class.new(host, {
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
    Timeout.timeout 60 do
      sleep 0.1 until host.libraries.all?(&:mapped?)
    end
    host.catalog
    message = described_class.new(host, {
                                    'params' => {
                                      'textDocument' => {
                                        'uri' => Solargraph::LanguageServer::UriHelpers.file_to_uri(File.join(
                                                                                                      path, 'lib', 'other.rb'
                                                                                                    ))
                                      },
                                      'position' => {
                                        'line' => 0,
                                        'character' => 10
                                      }
                                    }
                                  })
    message.process
    expect(message.result.first[:uri]).to eq(Solargraph::LanguageServer::UriHelpers.file_to_uri(File.join(path, 'lib',
                                                                                                          'thing.rb')))
  end

  it 'returns no locations when the file is not mapped yet' do
    library = instance_double(Solargraph::Library, locate_ref: nil)
    host = instance_double(Solargraph::LanguageServer::Host, definitions_at: nil, library_for: library)
    message = described_class.new(host, { 'params' => { 'textDocument' => { 'uri' => 'file:///unmapped.rb' }, 'position' => { 'line' => 0, 'character' => 0 } } })
    message.process
    expect(message.result).to eq([])
  end
end
