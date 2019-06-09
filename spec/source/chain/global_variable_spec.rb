describe Solargraph::Source::Chain::GlobalVariable do
  it "resolves instance variable pins" do
    closure = Solargraph::Pin::Namespace.new(name: 'Foo')
    foo_pin = Solargraph::Pin::GlobalVariable.new(closure: closure, name: '$foo')
    not_pin = Solargraph::Pin::InstanceVariable.new(closure: closure, name: '@bar')
    api_map = Solargraph::ApiMap.new
    api_map.index [foo_pin, not_pin]
    link = Solargraph::Source::Chain::GlobalVariable.new('$foo')
    pins = link.resolve(api_map, Solargraph::ComplexType.parse('Foo'), [])
    expect(pins.length).to eq(1)
    expect(pins.first.name).to eq('$foo')
  end
end
