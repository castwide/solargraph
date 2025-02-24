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
    multiple_types = Solargraph::ComplexType.parse 'Module<Foo>, Class<Bar>, String, nil'
    expect(multiple_types.length).to eq(4)
    expect(multiple_types.namespaces).to eq(['Foo', 'Bar', 'String', 'NilClass'])
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
    source = Solargraph::Source.load_string(%(
      module Foo
        class Bar
          # @return [Bar]
          def make_bar
          end
        end
      end
    ))
    api_map.map source
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

  it "returns string representations of the entire type array" do
    type = Solargraph::ComplexType.parse('String', 'Array<String>')
    expect(type.to_s).to eq('String, Array<String>')
  end

  it "returns the first type when multiple were parsed" do
    type = Solargraph::ComplexType.parse('String, Array<String>')
    expect(type.tag).to eq('String')
  end

  it "raises NoMethodError for missing methods" do
    type = Solargraph::ComplexType.parse('String')
    expect { type.undefined_method }.to raise_error(NoMethodError)
  end

  it "typifies Booleans" do
    api_map = double(Solargraph::ApiMap, qualify: nil)
    type = Solargraph::ComplexType.parse('Boolean')
    qualified = type.qualify(api_map)
    expect(qualified.tag).to eq('Boolean')
  end

  it "returns undefined for unqualified types" do
    api_map = double(Solargraph::ApiMap, qualify: nil)
    type = Solargraph::ComplexType.parse('UndefinedClass')
    qualified = type.qualify(api_map)
    expect(qualified).to be_undefined
  end

  it 'reports selfy types' do
    type = Solargraph::ComplexType.parse('self')
    expect(type).to be_selfy
  end

  it 'reports selfy parameter types' do
    type = Solargraph::ComplexType.parse('Class<self>')
    expect(type).to be_selfy
  end

  it 'resolves self keywords in types' do
    selfy = Solargraph::ComplexType.parse('self')
    type = selfy.self_to('Foo')
    expect(type.tag).to eq('Foo')
  end

  it 'resolves self keywords in parameter types' do
    selfy = Solargraph::ComplexType.parse('Array<self>')
    type = selfy.self_to('Foo')
    expect(type.tag).to eq('Array<Foo>')
  end

  it 'resolves self keywords in hash parameter types' do
    selfy = Solargraph::ComplexType.parse('Hash{String => self}')
    type = selfy.self_to('Foo')
    expect(type.tag).to eq('Hash{String => Foo}')
  end

  it 'resolves self keywords in ordered array types' do
    selfy = Solargraph::ComplexType.parse('Array<(String, Symbol, self)>')
    type = selfy.self_to('Foo')
    expect(type.tag).to eq('Array<(String, Symbol, Foo)>')
  end

  it 'qualifies special types' do
    api_map = Solargraph::ApiMap.new
    type = Solargraph::ComplexType.parse('nil')
    qual = type.qualify(api_map)
    expect(qual.tag).to eq('nil')
  end

  it 'parses a complex subtype' do
    type = Solargraph::ComplexType.parse('Array<self>').self_to('Foo<String>')
    expect(type.tag).to eq('Array<Foo<String>>')
  end

  it 'recognizes param types' do
    type = Solargraph::ComplexType.parse('param<Variable>')
    expect(type).to be_parameterized
  end

  it 'recognizes parameterized parameters' do
    type = Solargraph::ComplexType.parse('Object<param<Variable>>')
    expect(type).to be_parameterized
  end

  it 'reduces objects' do
    api_map = Solargraph::ApiMap.new
    selfy = Solargraph::ComplexType.parse('Object<self>')
    type = selfy.self_to('String')
    expect(type.tag).to eq('Object<String>')
    result = type.qualify(api_map)
    expect(result.tag).to eq('String')
  end

  it 'resolves generic parameters' do
    api_map = Solargraph::ApiMap.new
    return_type = Solargraph::ComplexType.parse('Array<param<GenericTypeParam>>')
    generic_class = Solargraph::Pin::Namespace.new(name: 'Foo', comments: '@generic GenericTypeParam')
    called_method = Solargraph::Pin::Method.new(
      location: Solargraph::Location.new('file:///foo.rb', Solargraph::Range.from_to(0, 0, 0, 0)),
      closure: generic_class,
      name: 'bar',
      comments: '@return [Foo<String>]'
    )
    type = return_type.resolve_parameters(generic_class, called_method.return_type)
    expect(type.tag).to eq('Array<String>')
  end
end
