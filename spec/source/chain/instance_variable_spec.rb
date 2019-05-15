describe Solargraph::Source::Chain::InstanceVariable do
  it "resolves instance variable pins" do
    closure = Solargraph::Pin::Namespace.new(name: 'Foo')
    methpin = Solargraph::Pin::Method.new(closure: closure, name: 'imeth', scope: :instance)
    foo_pin = Solargraph::Pin::InstanceVariable.new(closure: methpin, name: '@foo')
    bar_pin = Solargraph::Pin::InstanceVariable.new(closure: closure, name: '@foo')
    api_map = Solargraph::ApiMap.new
    api_map.index [closure, methpin, foo_pin, bar_pin]
    link = Solargraph::Source::Chain::InstanceVariable.new('@foo')
    pins = link.resolve(api_map, methpin, [])
    expect(pins.length).to eq(1)
    expect(pins.first.name).to eq('@foo')
    expect(pins.first.context.scope).to eq(:instance)
    pins = link.resolve(api_map, closure, [])
    expect(pins.length).to eq(1)
    expect(pins.first.name).to eq('@foo')
    expect(pins.first.context.scope).to eq(:class)
  end
end
