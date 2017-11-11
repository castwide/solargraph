describe Solargraph::LiveMap do
  it "accepts installations" do
    tmp = Class.new(Solargraph::Plugin::Base)
    expect(Solargraph::LiveMap.plugins.length).to eq(0)
    Solargraph::LiveMap.install(tmp)
    expect(Solargraph::LiveMap.plugins.length).to eq(1)
  end
end
