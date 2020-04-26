describe Solargraph::Source::Chain::Head do
  it "returns self pins" do
    head = Solargraph::Source::Chain::Head.new('self')
    npin = Solargraph::Pin::ProxyType.anonymous(Solargraph::ComplexType.parse('Foo'))
    ipin = head.resolve(nil, npin, []).first
    expect(ipin.return_type.namespace).to eq('Foo')
    expect(ipin.return_type.scope).to eq(:instance)
    # @todo This doesn't seem right
    cpin = Solargraph::Pin::Namespace.new(name: 'Foo')
    ipin = head.resolve(nil, cpin, []).first
    expect(ipin.return_type.namespace).to eq('Foo')
    expect(ipin.return_type.scope).to eq(:class)
  end
end
