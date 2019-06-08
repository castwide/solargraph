describe Solargraph::Source::Chain::Constant do
  it "resolves constants in the current context" do
    foo_pin = Solargraph::Pin::Constant.new(name: 'Foo')
    api_map = double(Solargraph::ApiMap, :get_constants => [foo_pin])
    link = described_class.new('Foo')
    pins = link.resolve(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(pins).to eq([foo_pin])
  end
end
