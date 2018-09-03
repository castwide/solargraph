describe Solargraph::SourceMap::Chain::GlobalVariable do
  it "resolves instance variable pins" do
    foo_pin = Solargraph::Pin::GlobalVariable.new(nil, 'Foo', '$foo', '', nil, nil, Solargraph::ComplexType.parse('Foo'))
    not_pin = Solargraph::Pin::InstanceVariable.new(nil, 'Foo', '@bar', '', nil, nil, Solargraph::ComplexType.parse('Foo'))
    api_map = Solargraph::ApiMap.new
    api_map.index [foo_pin, not_pin]
    link = Solargraph::SourceMap::Chain::GlobalVariable.new('$foo')
    pins = link.resolve(api_map, Solargraph::ComplexType.parse('Foo'), [])
    expect(pins.length).to eq(1)
    expect(pins.first.name).to eq('$foo')
  end
end
