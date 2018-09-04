describe Solargraph::Source::Chain::Head do
  it "returns self pins" do
    head = Solargraph::Source::Chain::Head.new('self')
    ipin = head.resolve(nil, Solargraph::ComplexType.parse('Foo'), []).first
    expect(ipin.return_type.namespace).to eq('Foo')
    expect(ipin.return_type.scope).to eq(:instance)
    ipin = head.resolve(nil, Solargraph::ComplexType.parse('Class<Foo>'), []).first
    expect(ipin.return_type.namespace).to eq('Foo')
    expect(ipin.return_type.scope).to eq(:class)
  end
end
