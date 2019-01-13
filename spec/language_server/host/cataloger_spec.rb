describe Solargraph::LanguageServer::Host::Cataloger do
  it "catalogs on ticks" do
    host = double(Solargraph::LanguageServer::Host)
    lib = double(Solargraph::Library)
    cataloger = Solargraph::LanguageServer::Host::Cataloger.new(host)
    cataloger.ping lib
    expect(lib).to receive(:catalog)
    cataloger.tick
  end
end
