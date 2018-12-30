describe Solargraph::LanguageServer::Message::Initialize do
  it "prepares workspace folders" do
    host = Solargraph::LanguageServer::Host.new
    dir = File.realpath(File.join('spec', 'fixtures', 'workspace'))
    init = Solargraph::LanguageServer::Message::Initialize.new(host, {
      'params' => {
        'capabilities' => {
          'workspace' => {
            'workspaceFolders' => true
          }
        },
        'workspaceFolders' => [
          {
            'uri' => Solargraph::LanguageServer::UriHelpers.file_to_uri(dir),
            'name' => 'workspace'
          }
        ]
      }
    })
    init.process
    expect(host.folders.length).to eq(1)
  end

  it "prepares rootUri as a workspace" do
    host = Solargraph::LanguageServer::Host.new
    dir = File.realpath(File.join('spec', 'fixtures', 'workspace'))
    init = Solargraph::LanguageServer::Message::Initialize.new(host, {
      'params' => {
        'capabilities' => {
          'workspace' => {
            'workspaceFolders' => true
          }
        },
        'rootUri' => Solargraph::LanguageServer::UriHelpers.file_to_uri(dir)
      }
    })
    init.process
    expect(host.folders.length).to eq(1)
  end

  it "prepares rootPath as a workspace" do
    host = Solargraph::LanguageServer::Host.new
    dir = File.realpath(File.join('spec', 'fixtures', 'workspace'))
    init = Solargraph::LanguageServer::Message::Initialize.new(host, {
      'params' => {
        'capabilities' => {
          'workspace' => {
            'workspaceFolders' => true
          }
        },
        'rootPath' => dir
      }
    })
    init.process
    expect(host.folders.length).to eq(1)
  end
end
