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
end
