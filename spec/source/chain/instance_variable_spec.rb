describe Solargraph::Source::Chain::InstanceVariable do
  it "resolves instance variable pins" do
    closure = Solargraph::Pin::Namespace.new(name: 'Foo',
                                             location: Solargraph::Location.new('test.rb', Solargraph::Range.from_to(1, 1, 9, 0)),
                                             source: :closure)
    methpin = Solargraph::Pin::Method.new(closure: closure, name: 'imeth', scope: :instance,
                                          location: Solargraph::Location.new('test.rb', Solargraph::Range.from_to(1, 1, 3, 0)),
                                          source: :methpin)
    foo_pin = Solargraph::Pin::InstanceVariable.new(closure: methpin, name: '@foo',
                                                    location: Solargraph::Location.new('test.rb', Solargraph::Range.from_to(2, 0, 2, 0)),
                                                    presence: Solargraph::Range.from_to(2, 0, 2, 4),
                                                    source: :foo_pin)
    bar_pin = Solargraph::Pin::InstanceVariable.new(closure: closure, name: '@foo',
                                                    location: Solargraph::Location.new('test.rb', Solargraph::Range.from_to(5, 0, 5, 0)),
                                                    presence: Solargraph::Range.from_to(5, 1, 5, 4),
                                                    source: :bar_pin)
    api_map = Solargraph::ApiMap.new
    api_map.index [closure, methpin, foo_pin, bar_pin]

    link = Solargraph::Source::Chain::InstanceVariable.new('@foo', nil, Solargraph::Location.new('test.rb', Solargraph::Range.from_to(2, 2, 2, 3)))
    pins = link.resolve(api_map, methpin, [])
    expect(pins.length).to eq(1)

    expect(pins.first.name).to eq('@foo')
    expect(pins.first.context.scope).to eq(:instance)
    # Lookup context is Class<Foo> to find the civar
    name_pin = Solargraph::Pin::ProxyType.anonymous(closure.binder,
                                                    # Closure is the class
                                                    closure: closure)
    link = Solargraph::Source::Chain::InstanceVariable.new('@foo', nil, Solargraph::Location.new('test.rb', Solargraph::Range.from_to(5, 1, 5, 2)))
    pins = link.resolve(api_map, name_pin, [])
    expect(pins.length).to eq(1)
    expect(pins.first.name).to eq('@foo')
    expect(pins.first.context.scope).to eq(:class)
  end
end
