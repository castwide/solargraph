require 'tmpdir'

describe Solargraph::LanguageServer::Host do
  it "prepares a workspace" do
    host = Solargraph::LanguageServer::Host.new
    Dir.mktmpdir do |dir|
      host.prepare (dir)
      # @todo Change this test or get rid of it. The library is private now.
      expect(host.send(:libraries).first).not_to be(nil)
    end
  end

  it "processes responses to message requests" do
    host = Solargraph::LanguageServer::Host.new
    done_somethings = 0
    host.send_request 'window/showMessageRequest', {
      'message' => 'Message',
      'actions' => ['Do something']
    } do |response|
      done_somethings += 1 if response == 'Do something'
    end
    expect(host.pending_requests.length).to eq(1)
    host.receive({
      'id' => host.pending_requests.first,
      'result' => 'Do something'
    })
    expect(done_somethings).to eq(1)
  end

  it "creates files from disk" do
    Dir.mktmpdir do |dir|
      host = Solargraph::LanguageServer::Host.new
      host.prepare dir
      file = File.join(dir, 'test.rb')
      File.write(file, "foo = 'foo'")
      uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(file)
      result = host.create(uri)
      expect(result).to be(true)
    end
  end

  it "deletes files" do
    Dir.mktmpdir do |dir|
      expect {
        host = Solargraph::LanguageServer::Host.new
        file = File.join(dir, 'test.rb')
        File.write(file, "foo = 'foo'")
        host.prepare dir
        uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(file)
        host.delete(uri)
      }.not_to raise_error
    end
  end

  it "cancels requests" do
    host = Solargraph::LanguageServer::Host.new
    host.cancel 1
    expect(host.cancel?(1)).to be(true)
  end

  it "runs diagnostics on opened files" do
    Dir.mktmpdir do |dir|
      host = Solargraph::LanguageServer::Host.new
      host.configure({ 'diagnostics' => true })
      file = File.join(dir, 'test.rb')
      File.write(file, "foo = 'foo'")
      host.start
      host.prepare dir
      uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(file)
      host.open(file, File.read(file), 1)
      buffer = host.flush
      times = 0
      # @todo Weak timeout for waiting until the diagnostics thread
      #   sends a notification
      while buffer.empty? && times < 10
        sleep 1
        times += 1
        buffer = host.flush
      end
      expect(buffer).to include('textDocument/publishDiagnostics')
      host.stop
    end
  end

  it "handles DiagnosticsErrors" do
    host = Solargraph::LanguageServer::Host.new
    library = double(:Library)
    allow(library).to receive(:diagnose).and_raise(Solargraph::DiagnosticsError)
    allow(library).to receive(:contain?).and_return(true)
    allow(library).to receive(:attach)
    allow(library).to receive(:merge)
    allow(library).to receive(:catalog)
    # @todo Smelly instance variable access
    host.instance_variable_set(:@libraries, [library])
    host.open('file:///test.rb', '', 0)
    expect {
      host.diagnose 'file:///test.rb'
    }.not_to raise_error
    result = host.flush
    expect(result).to include('Error in diagnostics')
  end

  it "opens multiple folders" do
    host = Solargraph::LanguageServer::Host.new
    app1_folder = File.absolute_path('spec/fixtures/workspace_folders/folder1').gsub(/\\/, '/')
    app2_folder = File.absolute_path('spec/fixtures/workspace_folders/folder2').gsub(/\\/, '/')
    host.prepare(app1_folder)
    host.prepare(app2_folder)
    file1_uri = Solargraph::LanguageServer::UriHelpers.file_to_uri("#{app1_folder}/app.rb")
    file2_uri = Solargraph::LanguageServer::UriHelpers.file_to_uri("#{app2_folder}/app.rb")
    host.open_from_disk file1_uri
    host.open_from_disk file2_uri
    app1_map = host.document_symbols(file1_uri).map(&:path)
    expect(app1_map).to include('Folder1App')
    expect(app1_map).not_to include('Folder2App')
    app2_map = host.document_symbols(file2_uri).map(&:path)
    expect(app2_map).to include('Folder2App')
    expect(app2_map).not_to include('Folder1App')
  end

  it "stops" do
    host = Solargraph::LanguageServer::Host.new
    host.stop
    expect(host.stopped?).to be(true)
  end

  it "retains orphaned sources" do
    dir = File.absolute_path('spec/fixtures/workspace')
    file = File.join(dir, 'lib', 'thing.rb')
    file_uri = Solargraph::LanguageServer::UriHelpers.uri_to_file(file)
    host = Solargraph::LanguageServer::Host.new
    host.prepare(dir)
    host.open(file_uri, File.read(file), 1)
    host.remove(dir)
    expect{
      host.document_symbols(file_uri)
    }.not_to raise_error
  end

  it "is unsynchronized after library changes" do
    host = Solargraph::LanguageServer::Host.new
    dir = File.absolute_path('spec/fixtures/workspace')
    file = File.join(dir, 'app.rb')
    file_uri = Solargraph::LanguageServer::UriHelpers.uri_to_file(file)
    host.prepare dir
    host.open file_uri, File.read(file), 0
    host.stop
    params = {
      'textDocument' => {
        'uri' => file_uri,
        'version' => 1
      },
      'contentChanges' => [
        {
          'range' => {
            'start' => {
              'line' => 2,
              'character' => 0
            },
            'end' => {
              'line' => 2,
              'character' => 0
            }
          },
          'text' => ';'
        }
      ]
    }
    expect(host.synchronizing?).to be(true)
    host.change params
  end

  it "responds with empty diagnostics for unopened files" do
    host = Solargraph::LanguageServer::Host.new
    host.diagnose 'file:///file.rb'
    response = host.flush
    # @todo Quick and dirty hack to get the data
    json = JSON.parse(response.lines.last)
    expect(json['method']).to eq('textDocument/publishDiagnostics')
    expect(json['params']['diagnostics']).to be_empty
  end

  it "rescues runtime errors from messages" do
    host = Solargraph::LanguageServer::Host.new
    message_class = Class.new(Solargraph::LanguageServer::Message::Base) do
      def process
        raise RuntimeError, 'Always raise an error from this message'
      end
    end
    Solargraph::LanguageServer::Message.register('raiseRuntimeError', message_class)
    expect {
      host.receive({
        'id' => 1,
        'method' => 'raiseRuntimeError',
        'params' => {}
      })
    }.not_to raise_error
  end

  it "ignores invalid messages" do
    host = Solargraph::LanguageServer::Host.new
    expect {
      host.receive({ 'bad' => 'message' })
    }.not_to raise_error
  end

  it 'unsynchronizes libraries after creating files' do
    Dir.mktmpdir do |dir|
      host = Solargraph::LanguageServer::Host.new
      host.prepare dir
      file = File.join(dir, 'foo.rb')
      uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(file)
      File.write file, 'class Foo; end'
      host.create uri
      expect(host.libraries.first).not_to be_synchronized
      # expect(host.libraries.first).to be_synchronized
      # expect(host.libraries.first.contain?(file)).to be(true)
    end
  end

  it 'unsynchronizes libraries after deleting files' do
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'foo.rb')
      uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(file)
      File.write file, 'class Foo; end'
      host = Solargraph::LanguageServer::Host.new
      host.prepare dir
      host.delete uri
      expect(host.libraries.first).not_to be_synchronized
      # expect(host.libraries.first).to be_synchronized
      # expect(host.libraries.first.contain?(file)).to be(false)
    end
  end

  describe "Workspace variations" do
    before :each do
      @host = Solargraph::LanguageServer::Host.new
    end

    after :each do
      @host.stop
    end

    it "creates a library for a file without a workspace" do
      @host.open('file:///file.rb', 'class Foo; end', 1)
      symbols = @host.document_symbols('file:///file.rb')
      expect(symbols).not_to be_empty
    end

    it "opens a file outside of prepared libraries" do
      @host.prepare(File.absolute_path(File.join('spec', 'fixtures', 'workspace')))
      @host.open('file:///file.rb', 'class Foo; end', 1)
      symbols = @host.document_symbols('file:///file.rb')
      expect(symbols).not_to be_empty
    end
  end
end
