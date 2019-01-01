describe Solargraph::LanguageServer::Host::Diagnoser do
  it "diagnoses on ticks" do
    host = double(Solargraph::LanguageServer::Host, options: { 'diagnostics' => true }, synchronizing?: false)
    diagnoser = Solargraph::LanguageServer::Host::Diagnoser.new(host)
    diagnoser.schedule 'file.rb'
    expect(host).to receive(:diagnose).with('file.rb')
    diagnoser.tick
  end
end
