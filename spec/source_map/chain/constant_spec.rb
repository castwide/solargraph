describe Solargraph::SourceMap::Chain::Constant do
  it "resolves constants in the current context" do
    context = Solargraph::ComplexType::ROOT
    foo_pin = Solargraph::Pin::Constant.new(nil, '', 'Foo', '', nil, nil, context, :public)
    api_map = double(Solargraph::ApiMap, :get_constants => [foo_pin])
    link = described_class.new('Foo')
    pins = link.resolve(api_map, context, [])
    expect(pins).to eq([foo_pin])
  end
end
