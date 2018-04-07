describe Solargraph::Pin::Namespace do
  it "handles long namespaces" do
    source = Solargraph::Source.load_string(%(
      class Foo::Bar
      end
    ))
    expect(source.namespace_pins.length).to eq(2)
    pin = source.namespace_pins[1]
    expect(pin.name).to eq('Bar')
    expect(pin.namespace).to eq('Foo')
    expect(pin.path).to eq('Foo::Bar')
  end
end
