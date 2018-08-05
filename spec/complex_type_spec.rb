describe Solargraph::ComplexType do
  it "parses a simple type" do
    types = Solargraph::ComplexType.parse 'String'
    expect(types.length).to eq(1)
    expect(types.first.tag).to eq('String')
    expect(types.first.name).to eq('String')
    expect(types.first.subtypes).to be_empty
  end

  it "parses multiple types" do
    types = Solargraph::ComplexType.parse 'String', 'Integer'
    expect(types.length).to eq(2)
    expect(types[0].tag).to eq('String')
    expect(types[1].tag).to eq('Integer')
  end

  it "parses multiple types in a string" do
    types = Solargraph::ComplexType.parse 'String, Integer'
    expect(types.length).to eq(2)
    expect(types[0].tag).to eq('String')
    expect(types[1].tag).to eq('Integer')
  end

  it "parses a subtype" do
    types = Solargraph::ComplexType.parse 'Array<String>'
    expect(types.length).to eq(1)
    expect(types.first.tag).to eq('Array<String>')
    expect(types.first.name).to eq('Array')
    expect(types.first.subtypes.length).to eq(1)
    expect(types.first.subtypes.first.name).to eq('String')
  end

  it "parses multiple subtypes" do
    types = Solargraph::ComplexType.parse 'Hash<Symbol, String>'
    expect(types.length).to eq(1)
    expect(types.first.tag).to eq('Hash<Symbol, String>')
    expect(types.first.name).to eq('Hash')
    expect(types.first.subtypes.length).to eq(2)
    expect(types.first.subtypes[0].name).to eq('Symbol')
    expect(types.first.subtypes[1].name).to eq('String')
  end

  it "detects namespace and scope for simple types" do
    types = Solargraph::ComplexType.parse 'Class'
    expect(types.length).to eq(1)
    expect(types.first.namespace).to eq('Class')
    expect(types.first.scope).to eq(:instance)
  end

  it "detects namespace and scope for classes with subtypes" do
    types = Solargraph::ComplexType.parse 'Class<String>'
    expect(types.length).to eq(1)
    expect(types.first.namespace).to eq('String')
    expect(types.first.scope).to eq(:class)
  end

  it "detects namespace and scope for modules with subtypes" do
    types = Solargraph::ComplexType.parse 'Module<Foo>'
    expect(types.length).to eq(1)
    expect(types.first.namespace).to eq('Foo')
    expect(types.first.scope).to eq(:class)
  end

  it "identifies duck types" do
    types = Solargraph::ComplexType.parse('#method')
    expect(types.length).to eq(1)
    expect(types.first.namespace).to eq('Object')
    expect(types.first.scope).to eq(:instance)
    expect(types.first.duck_type?).to be(true)
  end

  it "identifies nil types" do
    %w[nil Nil NIL].each do |t|
      types = Solargraph::ComplexType.parse(t)
      expect(types.length).to eq(1)
      expect(types.first.namespace).to eq('NilClass')
      expect(types.first.scope).to eq(:instance)
      expect(types.first.nil_type?).to be(true)
    end
  end
end
