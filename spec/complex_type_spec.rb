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

  it "identifies parametrized types" do
    types = Solargraph::ComplexType.parse('Array<String>, Hash{String => Symbol}, Array(String, Integer)')
    expect(types.all?(&:parameters?)).to be(true)
  end

  it "identifies list parameters" do
    types = Solargraph::ComplexType.parse('Array<String, Symbol>')
    expect(types.first.list_parameters?).to be(true)
  end

  it "identifies hash parameters" do
    types = Solargraph::ComplexType.parse('Hash{String => Integer}')
    expect(types.length).to eq(1)
    expect(types.first.hash_parameters?).to be(true)
    expect(types.first.tag).to eq('Hash{String => Integer}')
    expect(types.first.namespace).to eq('Hash')
    expect(types.first.substring).to eq('{String => Integer}')
    expect(types.first.key_types.map(&:name)).to eq(['String'])
    expect(types.first.value_types.map(&:name)).to eq(['Integer'])
  end

  it "identifies fixed parameters" do
    types = Solargraph::ComplexType.parse('Array(String, Symbol)')
    expect(types.first.fixed_parameters?).to be(true)
    expect(types.first.subtypes.map(&:namespace)).to eq(['String', 'Symbol'])
  end

  it "raises ComplexTypeError for unmatched brackets" do
    expect {
      Solargraph::ComplexType.parse('Array<String')
    }.to raise_error(Solargraph::ComplexTypeError)
    expect {
      Solargraph::ComplexType.parse('Array{String')
    }.to raise_error(Solargraph::ComplexTypeError)
    expect {
      Solargraph::ComplexType.parse('Array<String>>')
    }.to raise_error(Solargraph::ComplexTypeError)
    expect {
      Solargraph::ComplexType.parse('Array{String}}')
    }.to raise_error(Solargraph::ComplexTypeError)
    expect {
      Solargraph::ComplexType.parse('Array(String, Integer')
    }.to raise_error(Solargraph::ComplexTypeError)
    expect {
      Solargraph::ComplexType.parse('Array(String, Integer))')
    }.to raise_error(Solargraph::ComplexTypeError)
  end

  it "raises ComplexTypeError for hash parameters without key => value syntax" do
    expect {
      Solargraph::ComplexType.parse('Hash{Foo}')
    }.to raise_error(Solargraph::ComplexTypeError)
    expect {
      Solargraph::ComplexType.parse('Hash{Foo, Bar}')
    }.to raise_error(Solargraph::ComplexTypeError)
  end

  it "parses multiple key/value types in hash parameters" do
    types = Solargraph::ComplexType.parse("Hash{String, Symbol => Integer, BigDecimal}")
    expect(types.length).to eq(1)
    type = types.first
    expect(type.hash_parameters?).to eq(true)
    expect(type.key_types.map(&:name)).to eq(['String', 'Symbol'])
    expect(type.value_types.map(&:name)).to eq(['Integer', 'BigDecimal'])
  end

  it "parses recursive subtypes" do
    types = Solargraph::ComplexType.parse('Array<Hash{String => Integer}>')
    expect(types.length).to eq(1)
    expect(types.first.namespace).to eq('Array')
    expect(types.first.substring).to eq('<Hash{String => Integer}>')
    expect(types.first.subtypes.length).to eq(1)
    expect(types.first.subtypes.first.namespace).to eq('Hash')
    expect(types.first.subtypes.first.substring).to eq('{String => Integer}')
    expect(types.first.subtypes.first.key_types.map(&:namespace)).to eq(['String'])
    expect(types.first.subtypes.first.value_types.map(&:namespace)).to eq(['Integer'])
  end

  let (:foo_bar_api_map) {
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(%(
      module Foo
        class Bar
          # @return [Bar]
          def make_bar
          end
        end
      end
    ))
    api_map
  }

  it "qualifies types with list parameters" do
    original = Solargraph::ComplexType.parse('Class<Bar>').first
    qualified = original.qualify(foo_bar_api_map, 'Foo')
    expect(qualified.tag).to eq('Class<Foo::Bar>')
  end

  it "qualifies types with fixed parameters" do
    original = Solargraph::ComplexType.parse('Array(String, Bar)').first
    qualified = original.qualify(foo_bar_api_map, 'Foo')
    expect(qualified.tag).to eq('Array(String, Foo::Bar)')
  end

  it "qualifies types with hash parameters" do
    original = Solargraph::ComplexType.parse('Hash{String => Bar}').first
    qualified = original.qualify(foo_bar_api_map, 'Foo')
    expect(qualified.tag).to eq('Hash{String => Foo::Bar}')
  end
end
