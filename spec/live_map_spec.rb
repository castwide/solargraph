describe Solargraph::LiveMap do
  it "installs and uninstalls plugins" do
    current = Solargraph::LiveMap.plugins.length
    tmp = Class.new(Solargraph::Plugin::Base)
    Solargraph::LiveMap.install(tmp)
    expect(Solargraph::LiveMap.plugins.length).to eq(current + 1)
    Solargraph::LiveMap.uninstall(tmp)
    expect(Solargraph::LiveMap.plugins.length).to eq(current)
  end
end
