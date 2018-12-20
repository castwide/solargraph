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
    host.start({
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
      host.prepare dir
      uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(file)
      host.open(file, File.read(file), 1)
      buffer = host.flush
      times = 0
      # @todo Weak timeout for waiting until the diagnostics thread
      #   sends a notification
      while buffer.empty? and times < 10
        sleep 1
        times += 1
        buffer = host.flush
      end
      expect(buffer).to include('textDocument/publishDiagnostics')
    end
  end

  it "handles DiagnosticsErrors" do
    host = Solargraph::LanguageServer::Host.new
    library = double(:Library)
    allow(library).to receive(:diagnose).and_raise(Solargraph::DiagnosticsError)
    allow(library).to receive(:contain?).and_return(true)
    # @todo Smelly instance variable access
    host.instance_variable_set(:@libraries, [library])
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
end
