describe Solargraph::LanguageServer::Host::Diagnoser do
  it "diagnoses on ticks" do
    host = instance_double(Solargraph::LanguageServer::Host, options: { 'diagnostics' => true }, synchronizing?: false)
    allow(host).to receive(:diagnose)
    diagnoser = Solargraph::LanguageServer::Host::Diagnoser.new(host)
    diagnoser.schedule 'file.rb'
    diagnoser.tick
    expect(host).to have_received(:diagnose).with('file.rb')
  end
end
