describe Solargraph::SourceMap::Chain::InstanceVariable do
  it "resolves instance variable pins" do
    foo_pin = Solargraph::Pin::InstanceVariable.new(nil, 'Foo', '@foo', '', nil, nil, Solargraph::ComplexType.parse('Foo'))
    bar_pin = Solargraph::Pin::InstanceVariable.new(nil, 'Foo', '@foo', '', nil, nil, Solargraph::ComplexType.parse('Class<Foo>'))
    not_pin1 = Solargraph::Pin::InstanceVariable.new(nil, 'Foo', '@bar', '', nil, nil, Solargraph::ComplexType.parse('Foo'))
    not_pin2 = Solargraph::Pin::InstanceVariable.new(nil, 'Foo', '@bar', '', nil, nil, Solargraph::ComplexType.parse('Class<Foo>'))
    api_map = Solargraph::ApiMap.new
    api_map.index [foo_pin, bar_pin, not_pin1, not_pin2]
    link = Solargraph::SourceMap::Chain::InstanceVariable.new('@foo')
    pins = link.resolve(api_map, Solargraph::ComplexType.parse('Foo'), [])
    expect(pins.length).to eq(1)
    expect(pins.first.name).to eq('@foo')
    expect(pins.first.context.scope).to eq(:instance)
    pins = link.resolve(api_map, Solargraph::ComplexType.parse('Class<Foo>'), [])
    expect(pins.length).to eq(1)
    expect(pins.first.name).to eq('@foo')
    expect(pins.first.context.scope).to eq(:class)
  end
end
