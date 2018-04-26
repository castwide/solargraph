describe Solargraph::LanguageServer::Message do
  it "returns MethodNotFound for unregistered methods" do
    msg = Solargraph::LanguageServer::Message.select 'notARealMethod'
    expect(msg).to be(Solargraph::LanguageServer::Message::MethodNotFound)
  end

  it "returns MethodNotImplemented for unregistered $ methods" do
    msg = Solargraph::LanguageServer::Message.select '$/notARealMethod'
    expect(msg).to be(Solargraph::LanguageServer::Message::MethodNotImplemented)
  end
end
