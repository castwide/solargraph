describe Solargraph::Source::Chain::Head do
  it "returns self pins" do
    head = Solargraph::Source::Chain::Head.new('self')
    npin = Solargraph::Pin::ProxyType.anonymous(Solargraph::ComplexType.parse('Foo'))
    ipin = head.resolve(nil, npin, []).first
    expect(ipin.return_type.namespace).to eq('Foo')
    expect(ipin.return_type.scope).to eq(:instance)
    cpin = Solargraph::Pin::Namespace.new(nil, '', 'Foo', '', :class, :public, nil)
    ipin = head.resolve(nil, cpin, []).first
    expect(ipin.return_type.namespace).to eq('Foo')
    expect(ipin.return_type.scope).to eq(:class)
  end

  it "resolves super" do
    head = Solargraph::Source::Chain::Head.new('super')
    npin = Solargraph::Pin::Namespace.new(nil, '', 'Substring', '', :class, :public, 'String')
    mpin = Solargraph::Pin::Method.new(nil, 'Substring', 'upcase', '', :instance, :public, [])
    api_map = Solargraph::ApiMap.new(pins: [npin, mpin])
    spin = head.resolve(api_map, mpin, []).first
    expect(spin.path).to eq('String#upcase')
  end
end
