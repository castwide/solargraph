describe Solargraph::LanguageServer::Host::Diagnoser do
  it "diagnoses on ticks" do
    host = double(Solargraph::LanguageServer::Host, options: { 'diagnostics' => true }, synchronizing?: false)
    diagnoser = Solargraph::LanguageServer::Host::Diagnoser.new(host)
    diagnoser.schedule 'file.rb'
    allow(host).to receive(:diagnose)
    diagnoser.tick
    expect(host).to have_received(:diagnose).with('file.rb')
  end
end
