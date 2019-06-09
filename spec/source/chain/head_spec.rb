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

  it "resolves super" do
    head = Solargraph::Source::Chain::Head.new('super')
    npin = Solargraph::Pin::Namespace.new(name: 'Substring')
    scpin = Solargraph::Pin::Reference::Superclass.new(closure: npin, name: 'String')
    mpin = Solargraph::Pin::Method.new(closure: npin, name: 'upcase', scope: :instance, visibility: :public)
    api_map = Solargraph::ApiMap.new(pins: [npin, scpin, mpin])
    spin = head.resolve(api_map, mpin, []).first
    expect(spin.path).to eq('String#upcase')
  end
end
