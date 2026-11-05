# frozen_string_literal: true

describe Solargraph::LanguageServer::Host::Diagnoser do
  it 'diagnoses on ticks' do
    host = instance_double(Solargraph::LanguageServer::Host, options: { 'diagnostics' => true }, synchronizing?: false)
    allow(host).to receive(:diagnose)
    diagnoser = described_class.new(host)
    diagnoser.schedule 'file.rb'
    diagnoser.tick
    expect(host).to have_received(:diagnose).with('file.rb')
  end

  it 'skips the tick when another tick empties the queue first' do
    host = instance_double(Solargraph::LanguageServer::Host, synchronizing?: false)
    allow(host).to receive(:diagnose)
    diagnoser = described_class.new(host)
    calls = 0
    allow(host).to receive(:options) do
      calls += 1
      # Simulate a concurrent tick taking the queued file mid-check
      diagnoser.tick if calls == 1
      { 'diagnostics' => true }
    end
    diagnoser.schedule 'file.rb'
    diagnoser.tick
    expect(host).to have_received(:diagnose).once
  end
end
