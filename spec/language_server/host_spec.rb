require 'tmpdir'

describe Solargraph::LanguageServer::Host do
  it "prepares a workspace" do
    host = Solargraph::LanguageServer::Host.new
    Dir.mktmpdir do |dir|
      host.prepare (dir)
      # @todo Change this test or get rid of it. The library is private now.
      expect(host.send(:library)).not_to be(nil)
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
      while buffer.empty? and times < 5
        sleep 1
        times += 1
        buffer = host.flush
      end
      expect(buffer).to include('textDocument/publishDiagnostics')
    end
  end

  it "stops" do
    host = Solargraph::LanguageServer::Host.new
    host.stop
    expect(host.stopped?).to be(true)
  end
end
