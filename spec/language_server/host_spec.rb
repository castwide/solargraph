require 'tmpdir'

describe Solargraph::LanguageServer::Host do
  it 'prepares a workspace' do
    host = Solargraph::LanguageServer::Host.new
    Dir.mktmpdir do |dir|
      host.prepare(dir)
      expect(host.libraries.first).not_to be_nil
    end
  end

  it 'processes responses to message requests' do
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

  it 'creates files from disk' do
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

  it 'deletes files' do
    Dir.mktmpdir do |dir|
      expect do
        host = Solargraph::LanguageServer::Host.new
        file = File.join(dir, 'test.rb')
        File.write(file, "foo = 'foo'")
        host.prepare dir
        uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(file)
        host.delete(uri)
      end.not_to raise_error
    end
  end

  it 'cancels requests' do
    host = Solargraph::LanguageServer::Host.new
    host.cancel 1
    expect(host.cancel?(1)).to be(true)
  end

  it 'runs diagnostics on opened files' do
    Dir.mktmpdir do |dir|
      host = Solargraph::LanguageServer::Host.new
      host.configure({ 'diagnostics' => true })
      file = File.join(dir, 'test.rb')
      File.write(file, "foo = 'foo'")
      host.start
      host.prepare dir
      Solargraph::LanguageServer::UriHelpers.file_to_uri(file)
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

  it 'handles DiagnosticsErrors' do
    host = Solargraph::LanguageServer::Host.new
    library = double(:Library)
    allow(library).to receive(:diagnose).and_raise(Solargraph::DiagnosticsError)
    allow(library).to receive(:contain?).and_return(true)
    allow(library).to receive(:synchronized?).and_return(true)
    allow(library).to receive(:mapped?).and_return(true)
    allow(library).to receive(:attach)
    allow(library).to receive(:merge)
    allow(library).to receive(:catalog)
    # @todo Smelly instance variable access
    host.instance_variable_set(:@libraries, [library])
    host.open('file:///test.rb', '', 0)
    expect do
      host.diagnose 'file:///test.rb'
    end.not_to raise_error
    result = host.flush
    expect(result).to include('Error in diagnostics')
  end

  it 'opens multiple folders' do
    host = Solargraph::LanguageServer::Host.new
    app1_folder = File.absolute_path('spec/fixtures/workspace_folders/folder1').gsub('\\', '/')
    app2_folder = File.absolute_path('spec/fixtures/workspace_folders/folder2').gsub('\\', '/')
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

  it 'stops' do
    host = Solargraph::LanguageServer::Host.new
    host.stop
    expect(host.stopped?).to be(true)
  end

  it 'retains orphaned sources' do
    dir = File.absolute_path('spec/fixtures/workspace')
    file = File.join(dir, 'lib', 'thing.rb')
    file_uri = Solargraph::LanguageServer::UriHelpers.uri_to_file(file)
    host = Solargraph::LanguageServer::Host.new
    host.prepare(dir)
    host.open(file_uri, File.read(file), 1)
    host.remove(dir)
    expect do
      host.document_symbols(file_uri)
    end.not_to raise_error
  end

  it 'responds with empty diagnostics for unopened files' do
    host = Solargraph::LanguageServer::Host.new
    host.diagnose 'file:///file.rb'
    response = host.flush
    json = JSON.parse(response.lines.last)
    expect(json['method']).to eq('textDocument/publishDiagnostics')
    expect(json['params']['diagnostics']).to be_empty
  end

  it 'rescues runtime errors from messages' do
    host = Solargraph::LanguageServer::Host.new
    message_class = Class.new(Solargraph::LanguageServer::Message::Base) do
      def process
        raise 'Always raise an error from this message'
      end
    end
    Solargraph::LanguageServer::Message.register('raiseRuntimeError', message_class)
    expect do
      host.receive({
                     'id' => 1,
                     'method' => 'raiseRuntimeError',
                     'params' => {}
                   })
    end.not_to raise_error
  end

  it 'ignores invalid messages' do
    host = Solargraph::LanguageServer::Host.new
    expect do
      host.receive({ 'bad' => 'message' })
    end.not_to raise_error
  end

  it 'repairs simple breaking changes without incremental sync' do
    file = '/test.rb'
    uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(file)
    host = Solargraph::LanguageServer::Host.new
    host.prepare ''
    host.open uri, 'Foo::Bar', 1
    sleep 0.1 until host.libraries.all?(&:mapped?)
    host.change({
                  'textDocument' => {
                    'uri' => uri,
                    'version' => 2
                  },
                  'contentChanges' => [
                    {
                      'text' => 'Foo::Bar.'
                    }
                  ]
                })
    source = host.sources.find(uri)
    # @todo Smelly private method access
    expect(source.send(:repaired)).to eq('Foo::Bar ')
  end

  describe '#locate_pins' do
    it 'locates #initialize for Class#new calls' do
      code = %(
        class Example
          # the initialize method
          def initialize(foo); end
        end
        Foo.new
      )

      file = '/test.rb'
      uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(file)
      host = Solargraph::LanguageServer::Host.new
      host.prepare ''
      host.open uri, code, 1
      sleep 0.1 until host.libraries.all?(&:mapped?)
      result = host.locate_pins({
                                  'data' => {
                                    'uri' => uri,
                                    'location' => {
                                      'range' => {
                                        'start' => {
                                          'line' => 5,
                                          'character' => 12
                                        },
                                        'end' => {
                                          'line' => 5,
                                          'character' => 15
                                        }
                                      }
                                    },
                                    'path' => 'Example.new'
                                  }
                                })
      expect(result.map(&:path)).to include('Example.new')
    end
  end

  describe '#references_from' do
    it 'rescues FileNotFound errors' do
      host = Solargraph::LanguageServer::Host.new
      expect { host.references_from('file:///not_a_file.rb', 1, 1) }.not_to raise_error
    end

    it 'logs FileNotFound errors' do
      allow(Solargraph.logger).to receive(:warn)
      host = Solargraph::LanguageServer::Host.new
      host.references_from('file:///not_a_file.rb', 1, 1)
      expect(Solargraph.logger).to have_received(:warn).with(/FileNotFoundError/)
    end

    it 'rescues InvalidOffset errors' do
      host = Solargraph::LanguageServer::Host.new
      host.open('file:///file.rb', 'class Foo; end', 1)
      expect { host.references_from('file:///file.rb', 0, 100) }.not_to raise_error
    end

    it 'logs InvalidOffset errors' do
      allow(Solargraph.logger).to receive(:warn)
      host = Solargraph::LanguageServer::Host.new
      host.open('file:///file.rb', 'class Foo; end', 1)
      host.references_from('file:///file.rb', 0, 100)
      expect(Solargraph.logger).to have_received(:warn).with(/InvalidOffsetError/)
    end
  end

  describe 'Workspace variations' do
    before do
      @host = Solargraph::LanguageServer::Host.new
    end

    after do
      @host.stop
    end

    it 'creates a library for a file without a workspace' do
      @host.open('file:///file.rb', 'class Foo; end', 1)
      symbols = @host.document_symbols('file:///file.rb')
      expect(symbols).not_to be_empty
    end

    it 'opens a file outside of prepared libraries' do
      @host.prepare(File.absolute_path(File.join('spec', 'fixtures', 'workspace')))
      @host.open('file:///file.rb', 'class Foo; end', 1)
      symbols = @host.document_symbols('file:///file.rb')
      expect(symbols).not_to be_empty
    end
  end
end
