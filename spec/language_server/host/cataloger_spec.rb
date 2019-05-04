describe Solargraph::LanguageServer::Host::Cataloger do
  it "catalogs on ticks" do
    host = double(Solargraph::LanguageServer::Host)
    cataloger = Solargraph::LanguageServer::Host::Cataloger.new(host)
    expect(host).to receive(:catalog)
    cataloger.tick
  end
end
