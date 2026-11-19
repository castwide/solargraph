# frozen_string_literal: true

describe Solargraph::LanguageServer::Host::MessageWorker do
  it 'handle requests on queue' do
    host = instance_double(Solargraph::LanguageServer::Host)
    message = { 'method' => '$/example' }
    allow(host).to receive(:receive).with(message).and_return(nil)

    worker = described_class.new(host)
    worker.queue(message)
    expect(worker.messages).to eq [message]
    worker.tick
    expect(host).to have_received(:receive).with(message)
  end

  it 'keeps waiting after a wakeup with no message queued' do
    host = instance_double(Solargraph::LanguageServer::Host)
    message = { 'method' => '$/example' }
    allow(host).to receive(:receive).and_return(nil)

    worker = described_class.new(host)
    resource = instance_double(ConditionVariable)
    waits = 0
    # The first wait returns with nothing queued (a spurious wakeup); the
    # second returns after a message arrives.
    allow(resource).to receive(:wait) do
      waits += 1
      worker.messages.push(message) if waits == 2
    end
    worker.instance_variable_set(:@resource, resource)

    worker.tick

    expect(waits).to eq 2
    expect(host).to have_received(:receive).once.with(message)
  end
end
