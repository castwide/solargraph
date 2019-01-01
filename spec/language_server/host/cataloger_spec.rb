describe Solargraph::LanguageServer::Host::Cataloger do
  it "catalogs on ticks" do
    host = double(Solargraph::LanguageServer::Host)
    lib = double(Solargraph::Library)
    cataloger = Solargraph::LanguageServer::Host::Cataloger.new(host)
    cataloger.ping lib
    expect(host).to receive(:catalog).with(lib)
    cataloger.tick
  end
end
