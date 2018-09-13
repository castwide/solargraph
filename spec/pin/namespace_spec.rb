describe Solargraph::Pin::Namespace do
  # @todo The namespace_pins methods was only ever used in specs.
  it "handles long namespaces" do
    pin = Solargraph::Pin::Namespace.new(nil, 'Foo', 'Bar', '', :class, :public)
    expect(pin.path).to eq('Foo::Bar')
  end

  it "has class scope" do
    source = Solargraph::Source.load_string(%(
      class Foo
      end
    ))
    pin = Solargraph::Pin::Namespace.new(nil, '', 'Foo', '', :class, :public)
    expect(pin.context.scope).to eq(:class)
  end
end
