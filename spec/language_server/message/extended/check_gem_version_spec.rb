describe Solargraph::LanguageServer::Message::Extended::CheckGemVersion do
  it "checks the gem source" do
    host = Solargraph::LanguageServer::Host.new
    message = described_class.new(host, {})
    expect { message.process }.not_to raise_error
  end

  it "performs a verbose check" do
    host = Solargraph::LanguageServer::Host.new
    message = described_class.new(host, { 'params' => { 'verbose' => true } })
    expect { message.process }.not_to raise_error
  end

  it "detects available updates" do
    host = Solargraph::LanguageServer::Host.new
    message = described_class.new(host, {}, current: Gem::Version.new('0.0.1'))
    expect { message.process }.not_to raise_error
  end

  it "performs a verbose check with an available update" do
    host = Solargraph::LanguageServer::Host.new
    message = described_class.new(host, { 'params' => { 'verbose' => true } }, current: Gem::Version.new('0.0.1'))
    expect { message.process }.not_to raise_error
  end

  it "responds to update actions" do
    host = Solargraph::LanguageServer::Host.new
    message = Solargraph::LanguageServer::Message::Extended::CheckGemVersion.new(host, {}, current: Gem::Version.new('0.0.1'))
    message.process
    response = nil
    reader = Solargraph::LanguageServer::Transport::DataReader.new
    reader.set_message_handler do |data|
      response = data
    end
    reader.receive host.flush
    expect {
      action = {
        "id" => response['id'],
        "result" => response['params']['actions'].first
      }
      host.receive action
    }.not_to raise_error
  end
end
