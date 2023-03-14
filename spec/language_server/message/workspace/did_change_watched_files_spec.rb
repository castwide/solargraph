require 'tmpdir'

describe Solargraph::LanguageServer::Message::Workspace::DidChangeWatchedFiles do
  it 'adds created files to libraries' do
    Dir.mktmpdir do |dir|
      host = Solargraph::LanguageServer::Host.new
      host.prepare dir
      file = File.join(dir, 'foo.rb')
      File.write file, 'class Foo; end'
      uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(file)
      changed = Solargraph::LanguageServer::Message::Workspace::DidChangeWatchedFiles.new(host, {
        'method' => 'workspace/didChangeWatchedFiles',
        'params' => {
          'changes' => [
            {
              'type' => Solargraph::LanguageServer::Message::Workspace::DidChangeWatchedFiles::CREATED,
              'uri' => uri
            }
          ]
        }
      })
      changed.process
      expect(host.synchronizing?).to be(false)
      expect(host.library_for(uri)).to be_a(Solargraph::Library)
      expect(changed.error).to be_nil
    end
  end

  it 'removes deleted files from libraries' do
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'foo.rb')
      File.write file, 'class Foo; end'
      uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(file)
      host = Solargraph::LanguageServer::Host.new
      host.prepare dir
      changed = Solargraph::LanguageServer::Message::Workspace::DidChangeWatchedFiles.new(host, {
        'method' => 'workspace/didChangeWatchedFiles',
        'params' => {
          'changes' => [
            {
              'type' => Solargraph::LanguageServer::Message::Workspace::DidChangeWatchedFiles::DELETED,
              'uri' => uri
            }
          ]
        }
      })
      changed.process
      expect(host.synchronizing?).to be(false)
      expect {
        host.library_for(uri)
      }.to raise_error(Solargraph::FileNotFoundError)
    end
  end

  it 'updates changes files' do
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'foo.rb')
      File.write file, 'class Foo; end'
      uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(file)
      host = Solargraph::LanguageServer::Host.new
      host.prepare dir
      File.write file, 'class FooBar; end'
      changed = Solargraph::LanguageServer::Message::Workspace::DidChangeWatchedFiles.new(host, {
        'method' => 'workspace/didChangeWatchedFiles',
        'params' => {
          'changes' => [
            {
              'type' => Solargraph::LanguageServer::Message::Workspace::DidChangeWatchedFiles::CHANGED,
              'uri' => uri
            }
          ]
        }
      })
      changed.process
      expect(host.synchronizing?).to be(false)
      library = host.library_for(uri)
      expect(library.path_pins('Foo')).to be_empty
      expect(library.path_pins('FooBar')).not_to be_empty
      expect(changed.error).to be_nil
    end
  end

  it 'sets errors for invalid change types' do
    host = double(Solargraph::LanguageServer::Host, catalog: nil)
    allow(host).to receive(:create)
    allow(host).to receive(:delete)
    changed = Solargraph::LanguageServer::Message::Workspace::DidChangeWatchedFiles.new(host, {
      'method' => 'workspace/didChangeWatchedFiles',
      'params' => {
        'changes' => [
          {
            'type' => -1,
            'uri' => 'file:///foo.rb'
          }
        ]
      }
    })
    changed.process
    expect(changed.error).not_to be_nil
  end
end
