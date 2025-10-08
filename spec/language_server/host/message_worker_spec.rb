describe Solargraph::LanguageServer::Host::MessageWorker do
  it "handle requests on queue" do
    host = double(Solargraph::LanguageServer::Host)
    message = {'method' => '$/example'}
    allow(host).to receive(:receive).with(message).and_return(nil)

    worker = Solargraph::LanguageServer::Host::MessageWorker.new(host)
    worker.queue(message)
    expect(worker.messages).to eq [message]
    worker.tick
  end
end
