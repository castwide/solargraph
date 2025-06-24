describe Solargraph::ComplexType do
  it "parses a simple type" do
    types = Solargraph::ComplexType.parse 'String'
    expect(types.length).to eq(1)
    expect(types.first.tag).to eq('String')
    expect(types.first.name).to eq('String')
    expect(types.first.subtypes).to be_empty
    expect(types.first.to_rbs).to eq('String')
  end

  it "parses multiple types" do
    types = Solargraph::ComplexType.parse 'String', 'Integer'
    expect(types.length).to eq(2)
    expect(types[0].tag).to eq('String')
    expect(types[1].tag).to eq('Integer')
    expect(types.to_rbs).to eq('(String | Integer)')
  end

  it "parses multiple types in a string" do
    types = Solargraph::ComplexType.parse 'String, Integer'
    expect(types.length).to eq(2)
    expect(types[0].tag).to eq('String')
    expect(types[1].tag).to eq('Integer')
    expect(types.to_rbs).to eq('(String | Integer)')
  end

  it "parses a subtype" do
    types = Solargraph::ComplexType.parse 'Array<String>'
    expect(types.length).to eq(1)
    expect(types.first.tag).to eq('Array<String>')
    expect(types.first.name).to eq('Array')
    expect(types.first.subtypes.length).to eq(1)
    expect(types.first.subtypes.first.name).to eq('String')
    expect(types.to_rbs).to eq('Array[String]')
  end

  it "parses multiple subtypes" do
    types = Solargraph::ComplexType.parse 'Hash<Symbol, String>'
    expect(types.length).to eq(1)
    expect(types.first.tag).to eq('Hash<Symbol, String>')
    expect(types.first.name).to eq('Hash')
    expect(types.first.subtypes.length).to eq(2)
    expect(types.first.subtypes[0].name).to eq('Symbol')
    expect(types.first.subtypes[1].name).to eq('String')
    expect(types.to_rbs).to eq('Hash[Symbol, String]')
  end

  it "detects namespace and scope for simple types" do
    types = Solargraph::ComplexType.parse 'Class'
    expect(types.length).to eq(1)
    expect(types.first.namespace).to eq('Class')
    expect(types.first.scope).to eq(:instance)
    expect(types.to_rbs).to eq('Class')
  end

  it "identify rooted types" do
    types = Solargraph::ComplexType.parse '::Array'
    expect(types.map(&:rooted?)).to eq([true])
    expect(types.to_rbs).to eq('::Array')
  end

  it "identify unrooted types" do
    types = Solargraph::ComplexType.parse 'Array'
    expect(types.map(&:rooted?)).to eq([false])
  end

  it "detects namespace and scope for classes with subtypes" do
    types = Solargraph::ComplexType.parse 'Class<String>'
    expect(types.length).to eq(1)
    expect(types.first.namespace).to eq('String')
    expect(types.first.scope).to eq(:class)
    # RBS doesn't support individual class types like this
    expect(types.to_rbs).to eq('Class')
  end

  it "detects namespace and scope for modules with subtypes" do
    types = Solargraph::ComplexType.parse 'Module<Foo>'
    expect(types.length).to eq(1)
    expect(types.first.namespace).to eq('Foo')
    expect(types.first.scope).to eq(:class)
    expect(types.to_rbs).to eq('Module')
    multiple_types = Solargraph::ComplexType.parse 'Module<Foo>, Class<Bar>, String, nil'
    expect(multiple_types.length).to eq(4)
    expect(multiple_types.namespaces).to eq(['Foo', 'Bar', 'String', 'NilClass'])
    # RBS doesn't support individual module types like this
    expect(multiple_types.to_rbs).to eq('(Module | Class | String | nil)')
  end

  it "identifies duck types" do
    types = Solargraph::ComplexType.parse('#method')
    expect(types.length).to eq(1)
    expect(types.first.namespace).to eq('Object')
    expect(types.first.scope).to eq(:instance)
    expect(types.first.duck_type?).to be(true)
    expect(types.to_rbs).to eq('untyped')
  end

  it "identifies nil types" do
    %w[nil Nil NIL].each do |t|
      types = Solargraph::ComplexType.parse(t)
      expect(types.length).to eq(1)
      expect(types.first.namespace).to eq('NilClass')
      expect(types.first.scope).to eq(:instance)
      expect(types.first.nil_type?).to be(true)
      expect(types.to_rbs).to eq('nil')
    end
  end

  it "identifies parametrized types" do
    types = Solargraph::ComplexType.parse('Array<String>, Hash{String => Symbol}, Array(String, Integer)')
    expect(types.all?(&:parameters?)).to be(true)
    expect(types.to_rbs).to eq('(Array[String] | Hash[String, Symbol] | [String, Integer])')
  end

  it "identifies list parameters" do
    types = Solargraph::ComplexType.parse('Array<String, Symbol>')
    expect(types.first.list_parameters?).to be(true)
    expect(types.to_rbs).to eq('Array[String, Symbol]')
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
    expect(types.to_rbs).to eq('Hash[String, Integer]')
  end

  it "identifies fixed parameters" do
    types = Solargraph::ComplexType.parse('Array(String, Symbol)')
    expect(types.first.fixed_parameters?).to be(true)
    expect(types.first.subtypes.map(&:namespace)).to eq(['String', 'Symbol'])
    # RBS doesn't use a type name for tuples, just the [] shorthand
    expect(types.to_rbs).to eq('[String, Symbol]')
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
    expect(type.to_rbs).to eq('Hash[(String | Symbol), (Integer | BigDecimal)]')
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
    expect(types.to_rbs).to eq('Array[Hash[String, Integer]]')
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
    expect(original).not_to be_rooted
    qualified = original.qualify(foo_bar_api_map, 'Foo')
    expect(qualified.tag).to eq('Class<Foo::Bar>')
    expect(qualified.rooted_tag).to eq('::Class<::Foo::Bar>')
    expect(qualified).to be_rooted
    expect(qualified.to_rbs).to eq('::Class')
  end

  it "qualifies types with fixed parameters" do
    original = Solargraph::ComplexType.parse('Array(String, Bar)').first
    expect(original.to_rbs).to eq('[String, Bar]')
    qualified = original.qualify(foo_bar_api_map, 'Foo')
    expect(qualified).to be_rooted
    expect(qualified.tag).to eq('Array(String, Foo::Bar)')
    expect(qualified.to_rbs).to eq('[::String, ::Foo::Bar]')
  end

  it "qualifies types with hash parameters" do
    original = Solargraph::ComplexType.parse('Hash{String => Bar}').first
    qualified = original.qualify(foo_bar_api_map, 'Foo')
    expect(qualified.tag).to eq('Hash{String => Foo::Bar}')
    expect(qualified.to_rbs).to eq('::Hash[::String, ::Foo::Bar]')
  end

  it "returns string representations of the entire type array" do
    type = Solargraph::ComplexType.parse('String', 'Array<String>')
    expect(type.to_s).to eq('String, Array<String>')
    # we want this surrounded by () so that it can be composed with
    # other types without worrying about operator precedence
    expect(type.to_rbs).to eq('(String | Array[String])')
  end

  it "returns the first type when multiple were parsed with #tag" do
    type = Solargraph::ComplexType.parse('String, Array<String>')
    expect(type.tag).to eq('String')
    expect(type.to_rbs).to eq('(String | Array[String])')
  end

  it "raises NoMethodError for missing methods" do
    type = Solargraph::ComplexType.parse('String')
    expect { type.undefined_method }.to raise_error(NoMethodError)
  end

  it "typifies Booleans" do
    api_map = double(Solargraph::ApiMap, qualify: nil)
    type = Solargraph::ComplexType.parse('::Boolean')
    qualified = type.qualify(api_map)
    expect(qualified.tag).to eq('Boolean')
    expect(qualified.to_rbs).to eq('bool')
  end

  it "does not typify non-rooted Booleans" do
    api_map = double(Solargraph::ApiMap, qualify: nil)
    type = Solargraph::ComplexType.parse('Boolean')
    expect(type.rooted_tag).to eq('Boolean')
    expect(type.to_rbs).to eq('bool')
  end

  it "returns undefined for unqualified types" do
    api_map = double(Solargraph::ApiMap, qualify: nil)
    type = Solargraph::ComplexType.parse('UndefinedClass')
    qualified = type.qualify(api_map)
    expect(qualified).to be_undefined
    expect(qualified.to_rbs).to eq('untyped')
  end

  it 'reports selfy types' do
    type = Solargraph::ComplexType.parse('self')
    expect(type).to be_selfy
    expect(type.to_rbs).to eq('self')
  end

  it 'reports selfy parameter types' do
    type = Solargraph::ComplexType.parse('Class<self>')
    expect(type).to be_selfy
    expect(type.to_rbs).to eq('Class')
  end

  it 'resolves self keywords in types' do
    selfy = Solargraph::ComplexType.parse('self')
    type = selfy.self_to_type(Solargraph::ComplexType.parse('Foo'))
    expect(type.tag).to eq('Foo')
  end

  it 'resolves self keywords in parameter types' do
    selfy = Solargraph::ComplexType.parse('Array<self>')
    type = selfy.self_to_type(Solargraph::ComplexType.parse('Foo'))
    expect(type.tag).to eq('Array<Foo>')
  end

  it 'resolves self keywords in hash parameter types' do
    selfy = Solargraph::ComplexType.parse('Hash{String => self}')
    type = selfy.self_to_type(Solargraph::ComplexType.parse('Foo'))
    expect(type.tag).to eq('Hash{String => Foo}')
    expect(type.to_rbs).to eq('Hash[String, Foo]')
  end

  it 'resolves self keywords in ordered array types' do
    selfy = Solargraph::ComplexType.parse('Array<(String, Symbol, self)>')
    type = selfy.self_to_type(Solargraph::ComplexType.parse('Foo'))
    expect(type.tag).to eq('Array<(String, Symbol, Foo)>')
    expect(type.to_rbs).to eq('Array[[String, Symbol, Foo]]')
  end

  it 'qualifies special types' do
    api_map = Solargraph::ApiMap.new
    type = Solargraph::ComplexType.parse('nil')
    qual = type.qualify(api_map)
    expect(qual.tag).to eq('nil')
    expect(qual.to_rbs).to eq('nil')
  end

  it 'parses a complex subtype' do
    type = Solargraph::ComplexType.parse('Array<self>').self_to_type(Solargraph::ComplexType.parse('Foo<String>'))
    expect(type.tag).to eq('Array<Foo<String>>')
    expect(type.to_rbs).to eq('Array[Foo[String]]')
  end

  it 'recognizes param types' do
    type = Solargraph::ComplexType.parse('generic<Variable>')
    expect(type).to be_generic
    expect(type.to_rbs).to eq('Variable')
  end

  it 'recognizes generic parameters' do
    type = Solargraph::ComplexType.parse('Array<generic<Variable>>')
    expect(type).to be_generic
    expect(type.to_rbs).to eq('Array[Variable]')
  end

  it 'recognizes generic parameters of hash parameter types' do
    type = Solargraph::ComplexType.parse('Hash{generic<Variable> => generic<Other>}')
    expect(type.tag).to eq('Hash{generic<Variable> => generic<Other>}')
    expect(type.to_rbs).to eq('Hash[Variable, Other]')
  end

  it 'reduces objects' do
    api_map = Solargraph::ApiMap.new
    selfy = Solargraph::ComplexType.parse('Array<self>')
    type = selfy.self_to_type(Solargraph::ComplexType.parse('String'))
    expect(type.tag).to eq('Array<String>')
    expect(type.to_rbs).to eq('Array[String]')
    result = type.qualify(api_map)
    expect(result.tag).to eq('Array<String>')
    expect(result.to_rbs).to eq('::Array[::String]')
  end

  UNIQUE_METHOD_GENERIC_TESTS = [
    # tag, context_type_tag, unfrozen_input_map, expected_tag, expected_output_map
    ['String', 'String', {}, 'String', {}],
    ['generic<A>', 'String', {}, 'String', {'A' => 'String'}],
    ['generic<A>', 'Array<String>', {}, 'Array<String>', {'A' => 'Array<String>'}],
    ['generic<A>', 'Array<String>', {'A' => 'String'}, 'String', {'A' => 'String'}],
    ['generic<A>', 'Array<generic<B>>', {'B' => 'Integer'}, 'Array<Integer>', {'B' => 'Integer', 'A' => 'Array<Integer>'}],
    ['Array<generic<A>>', 'Array<String>', {}, 'Array<String>', {'A' => 'String'}],
  ]

  UNIQUE_METHOD_GENERIC_TESTS.each do |tag, context_type_tag, unfrozen_input_map, expected_tag, expected_output_map|
    context "resolves #{tag} with context #{context_type_tag} and existing resolved generics #{unfrozen_input_map}" do
      let(:complex_type) { Solargraph::ComplexType.parse(tag) }
      let(:unique_type) { unique_type = complex_type.first }

      it '#{tag} is a unique type' do
        expect(complex_type.length).to eq(1)
      end

      let(:generic_value) { unfrozen_input_map.transform_values! { |tag| Solargraph::ComplexType.parse(tag) } }
      let(:context_type) { Solargraph::ComplexType.parse(context_type_tag) }

      it "resolves to #{expected_tag} with updated map #{expected_output_map}" do
        resolved_generic_values = unfrozen_input_map.transform_values { |tag| Solargraph::ComplexType.parse(tag) }
        resolved_type = unique_type.resolve_generics_from_context(expected_output_map.keys, context_type, resolved_generic_values: resolved_generic_values)
        expect(resolved_type.tag).to eq(expected_tag)
        expect(resolved_generic_values.transform_values(&:tag)).to eq(expected_output_map)
      end
    end
  end

  it 'resolves generic namespace parameters' do
    return_type = Solargraph::ComplexType.parse('Array<generic<GenericTypeParam>>')
    generic_class = Solargraph::Pin::Namespace.new(name: 'Foo', comments: '@generic GenericTypeParam')
    called_method = Solargraph::Pin::Method.new(
      location: Solargraph::Location.new('file:///foo.rb', Solargraph::Range.from_to(0, 0, 0, 0)),
      closure: generic_class,
      name: 'bar',
      comments: '@return [Foo<String>]'
    )
    type = return_type.resolve_generics(generic_class, called_method.return_type)
    expect(type.tag).to eq('Array<String>')
  end

  it 'resolves generic parameters on a tuple using ()' do
    return_type = Solargraph::ComplexType.parse('Array(generic<GenericTypeParam1>, generic<GenericTypeParam2>)')
    generic_class = Solargraph::Pin::Namespace.new(name: 'Foo', comments: "@generic GenericTypeParam1\n@generic GenericTypeParam2")
    called_method = Solargraph::Pin::Method.new(
      location: Solargraph::Location.new('file:///foo.rb', Solargraph::Range.from_to(0, 0, 0, 0)),
      closure: generic_class,
      name: 'bar',
      comments: '@return [Foo<String, Integer>]'
    )
    type = return_type.resolve_generics(generic_class, called_method.return_type)
    expect(type.tag).to eq('Array(String, Integer)')
  end

  it 'resolves generic parameters on a tuple using <()>' do
    return_type = Solargraph::ComplexType.parse('Array<(generic<GenericTypeParam1>, generic<GenericTypeParam2>)>')
    generic_class = Solargraph::Pin::Namespace.new(name: 'Foo', comments: "@generic GenericTypeParam1\n@generic GenericTypeParam2")
    called_method = Solargraph::Pin::Method.new(
      location: Solargraph::Location.new('file:///foo.rb', Solargraph::Range.from_to(0, 0, 0, 0)),
      closure: generic_class,
      name: 'bar',
      comments: '@return [Foo<String, Integer>]'
    )
    type = return_type.resolve_generics(generic_class, called_method.return_type)
    expect(type.tag).to eq('Array<(String, Integer)>')
  end

  # See literal details at
  # https://github.com/ruby/rbs/blob/master/docs/syntax.md and
  # https://yardoc.org/types.html
  xit 'understands literal strings with double quotes' do
    type = Solargraph::ComplexType.parse('"foo"')
    expect(type.tag).to eq('"foo"')
    expect(type.to_rbs).to eq('"foo"')
    expect(type.to_s).to eq('String')
  end

  xit 'understands literal strings with single quotes' do
    type = Solargraph::ComplexType.parse("'foo'")
    expect(type.tag).to eq("'foo'")
    expect(type.to_rbs).to eq("'foo'")
    expect(type.to_s).to eq('String')
  end

  it 'understands literal symbols' do
    type = Solargraph::ComplexType.parse(':foo')
    expect(type.tag).to eq(':foo')
    expect(type.to_rbs).to eq(':foo')
    expect(type.to_s).to eq(':foo')
  end

  it 'understands literal integers' do
    type = Solargraph::ComplexType.parse('123')
    expect(type.tag).to eq('123')
    expect(type.to_rbs).to eq('123')
    expect(type.to_s).to eq('123')
  end

  it 'understands literal true' do
    type = Solargraph::ComplexType.parse('true')
    expect(type.tag).to eq('true')
    expect(type.to_rbs).to eq('true')
    expect(type.to_s).to eq('true')
  end

  it 'understands literal false' do
    type = Solargraph::ComplexType.parse('false')
    expect(type.tag).to eq('false')
    expect(type.to_rbs).to eq('false')
    expect(type.to_s).to eq('false')
  end

  it 'parses tuples of tuples' do
    type = Solargraph::ComplexType.parse('Array(Array(String), String)')
    expect(type.tag).to eq('Array(Array(String), String)')
    expect(type.to_rbs).to eq('[[String], String]')
    expect(type.to_s).to eq('Array(Array(String), String)')
  end

  it 'parses tuples of tuples with same type twice in a row' do
    type = Solargraph::ComplexType.parse('Array(Symbol, String, Array(Integer, Integer))')
    expect(type.tag).to eq('Array(Symbol, String, Array(Integer, Integer))')
    expect(type.to_rbs).to eq('[Symbol, String, [Integer, Integer]]')
    expect(type.to_s).to eq('Array(Symbol, String, Array(Integer, Integer))')
  end

  it 'qualifies tuples of tuples with same type twice in a row' do
    api_map = Solargraph::ApiMap.new
    type = Solargraph::ComplexType.parse('Array(Symbol, String, Array(Integer, Integer))')
    type = type.qualify(api_map)
    expect(type.to_s).to eq('Array(Symbol, String, Array(Integer, Integer))')
    expect(type.to_rbs).to eq('[::Symbol, ::String, [::Integer, ::Integer]]')
  end

  it 'throws away other types when in union with an undefined' do
    type = Solargraph::ComplexType.parse('Symbol, String, Array(Integer, Integer), undefined')
    expect(type.to_s).to eq('undefined')
  end

  it 'deduplicates types that are implicit unions' do
    type = Solargraph::ComplexType.parse('Array<Symbol, String, Symbol>')
    expect(type.to_s).to eq('Array<Symbol, String>')
  end

  it "does not deduplicate types that aren't implicit unions" do
    type = Solargraph::ComplexType.parse('Foo<Symbol, String, Symbol>')
    expect(type.to_s).to eq('Foo<Symbol, String, Symbol>')
  end

  it 'squashes literal types when simplifying literals of same type' do
    api_map = Solargraph::ApiMap.new
    type = Solargraph::ComplexType.parse('1, 2, 3')
    type = type.qualify(api_map)
    expect(type.to_s).to eq('1, 2, 3')
    expect(type.tags).to eq('1, 2, 3')
    expect(type.simple_tags).to eq('Integer')
    expect(type.to_rbs).to eq('(1 | 2 | 3)')
  end

  xit 'stops parsing when the first character indicates a string literal' do
    api_map = Solargraph::ApiMap.new
    type = Solargraph::ComplexType.parse('"Array(Symbol, String, Array(Integer, Integer)"')
    type = type.qualify(api_map)
    expect(type.tag).to eq('Array(Symbol, String, Array(Integer, Integer))')
    expect(type.to_rbs).to eq('[Symbol, String, [Integer, Integer]]')
    expect(type.to_s).to eq('Array(Symbol, String, Array(Integer, Integer))')
  end

  ['generic<T>', "nil", "true", "false", ":123", "123"].each do |tag|
    it "treats #{tag} as rooted" do
      types = Solargraph::ComplexType.parse(tag)
      expect(types.all?(&:rooted?)).to be(true)
    end
  end
end
