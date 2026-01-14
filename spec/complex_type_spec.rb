describe 'YARD type specifier list parsing' do
  context 'with https://www.rubydoc.info/gems/yard/file/docs/Tags.md#type-list-conventions compliance' do
    # Types Specifier List
    #
    # In some cases, a tag will allow for a "types specifier list"; this
    # will be evident from the use of the [Types] syntax in the tag
    # signature. A types specifier list is a comma separated list of
    # types, most often classes or modules, but occasionally
    # literals.
    #
    it 'parses zero types as separate arguments' do
      types = Solargraph::ComplexType.parse
      expect(types.length).to eq(0)
    end

    it 'parses zero types as a string' do
      pending('special case being added')
      types = Solargraph::ComplexType.parse ''
      expect(types.length).to eq(0)
    end

    it 'parses a single type' do
      types = Solargraph::ComplexType.parse 'String'
      expect(types.length).to eq(1)
      expect(types.first.tag).to eq('String')
      expect(types.first.name).to eq('String')
      expect(types.first.subtypes).to be_empty
      expect(types.first.to_rbs).to eq('String')
    end

    it 'parses multiple types as separate arguments' do
      types = Solargraph::ComplexType.parse 'String', 'Integer'
      expect(types.length).to eq(2)
      expect(types[0].tag).to eq('String')
      expect(types[1].tag).to eq('Integer')
      expect(types.to_rbs).to eq('(String | Integer)')
    end

    it 'parses multiple types in a string' do
      types = Solargraph::ComplexType.parse 'String, Integer'
      expect(types.length).to eq(2)
      expect(types[0].tag).to eq('String')
      expect(types[1].tag).to eq('Integer')
      expect(types.to_rbs).to eq('(String | Integer)')
    end

    # For example, the following @return tag lists a set of
    # types returned by a method:
    #
    #   # Finds an object or list of objects in the db using a query
    #   # @return [String, Array<String>, nil] the object or objects to
    #   #   find in the database. Can be nil.
    #   def find(query) finder_code_here end
    it 'parses class, generic class and literal in a string' do
      types = Solargraph::ComplexType.parse 'String, Array<String>, nil'
      expect(types.length).to eq(3)
      expect(types[0].tag).to eq('String')
      expect(types[1].tag).to eq('Array<String>')
      expect(types[2].tag).to eq('nil')
      expect(types.to_rbs).to eq('(String | Array[String] | nil)')
    end

    #
    # A list of conventions for type names is specified
    # below. Typically, however, any Ruby literal or class/module is
    # allowed here.
    #
    #
    # Duck-types (method names prefixed with "#") are also
    # allowed.
    it 'parses duck types' do
      types = Solargraph::ComplexType.parse('#method')
      expect(types.length).to eq(1)
      expect(types.first.namespace).to eq('Object')
      expect(types.first.scope).to eq(:instance)
      expect(types.first.duck_type?).to be(true)
      # RBS solves this problem with type-only signatures
      expect(types.to_rbs).to eq('untyped')
    end

    #
    # Note that the type specifier list is always an optional field and
    # can be omitted when present in a tag signature. This is the reason
    # why it is surrounded by brackets. It is also a freeform list, and
    # can contain any list of values, though a set of conventions for
    # how to list types is described below.
    #
    # Type List Conventions
    #
    # A list of examples of common type listings and what they translate
    # into is available at http://yardoc.org/types.
    #
    xit 'parses type examples from http://yardoc.org/types'
    #
    # Typically, a type list contains a list of classes or modules that
    # are associated with the tag. In some cases, however, certain
    # special values are allowed or required to be listed. This section
    # discusses the syntax for specifying Ruby types inside of type
    # specifier lists, as well as the other non-Ruby types that are
    # accepted by convention in these lists.
    #
    # It's important to realize that the conventions listed here may not
    # always adequately describe every type signature, and is not meant
    # to be a complete syntax. This is why the types specifier list is
    # freeform and can contain any set of values. The conventions
    # defined here are only conventions, and if they do not work for
    # your type specifications, you can define your own appropriate
    # conventions.
    #
    # Note that a types specifier list might also be used for non-Type
    # values. In this case, the tag documentation will describe what
    # values are allowed within the type specifier list.
    #
    # Class or Module Types
    #
    # Any Ruby type is allowed as a class or module type. Such a type is
    # simply the name of the class or module.

    # Note that one extra type that is accepted by convention is the
    # Boolean type, which represents both the TrueClass and FalseClass
    # types. This type does not exist in Ruby, however.

    it 'typifies Booleans' do
      api_map = instance_double(Solargraph::ApiMap, qualify: nil)
      type = Solargraph::ComplexType.parse('::Boolean')
      qualified = type.qualify(api_map)
      expect(qualified.tag).to eq('Boolean')
      expect(qualified.to_rbs).to eq('bool')
    end

    # Parametrized Types
    #
    # In addition to basic types (like String or Array), YARD
    # conventions allow for a "generics" like syntax to specify
    # container objects or other parametrized types. The syntax is
    # Type<SubType, OtherSubType, ...>. For instance, an Array might
    # contain only String objects, in which case the type specification
    # would be Array<String>.

    it 'parses a subtype' do
      types = Solargraph::ComplexType.parse 'Array<String>'
      expect(types.length).to eq(1)
      expect(types.first.tag).to eq('Array<String>')
      expect(types.first.name).to eq('Array')
      expect(types.first.subtypes.length).to eq(1)
      expect(types.first.subtypes.first.name).to eq('String')
      expect(types.to_rbs).to eq('Array[String]')
    end

    # Multiple parametrized types can be listed, separated by commas.

    it 'parses multiple subtypes' do
      types = Solargraph::ComplexType.parse 'Array<Symbol, String>'
      expect(types.length).to eq(1)
      expect(types.first.tag).to eq('Array<Symbol, String>')
      expect(types.first.name).to eq('Array')
      expect(types.first.subtypes.length).to eq(2)
      expect(types.first.subtypes[0].name).to eq('Symbol')
      expect(types.first.subtypes[1].name).to eq('String')
      expect(types.to_rbs).to eq('Array[Symbol, String]')
    end


    # Note that parametrized types are typically not order-dependent, in
    # other words, a list of parametrized types can occur in any order
    # inside of a type. An array specified as Array<String, Fixnum> can
    # contain any amount of Strings or Fixnums, in any order. When the
    # order matters, use "order-dependent lists", described below.
    #
    # Duck-Types
    #
    # Duck-types are allowed in type specifier lists, and are identified
    # by method names beginning with the "#" prefix. Typically,
    # duck-types are recommended for @param tags only, though they can
    # be used in other tags if needed. The following example shows a
    # method that takes a parameter of any type that responds to the
    # "read" method:
    #
    # # Reads from any I/O object.
    # # @param io [#read] the input object to read from
    # def read(io) io.read end

    #
    # Hashes
    #

    # Hashes can be specified either via the parametrized type discussed
    # above, in the form Hash<KeyType, ValueType>, or using the hash
    # specific syntax: Hash{KeyTypes=>ValueTypes}.
    it 'parses Hash using hash rocket notation' do
      types = Solargraph::ComplexType.parse('Hash{String => Integer}')
      expect(types.length).to eq(1)
      expect(types.first.tag).to eq('Hash{String => Integer}')
      expect(types.first.namespace).to eq('Hash')
      expect(types.first.substring).to eq('{String => Integer}')
      expect(types.first.key_types.map(&:name)).to eq(['String'])
      expect(types.first.value_types.map(&:name)).to eq(['Integer'])
      expect(types.to_rbs).to eq('Hash[String, Integer]')
    end

    it 'parses Hash using <> notation' do
      types = Solargraph::ComplexType.parse 'Hash<Symbol, String>'
      expect(types.length).to eq(1)
      expect(types.first.tag).to eq('Hash<Symbol, String>')
      expect(types.first.name).to eq('Hash')
      expect(types.first.key_types.length).to eq(1)
      expect(types.first.key_types[0].name).to eq('Symbol')
      expect(types.first.subtypes.length).to eq(1)
      expect(types.first.subtypes[0].name).to eq('String')
      expect(types.to_rbs).to eq('Hash[Symbol, String]')
    end

    # In the latter case, KeyTypes or ValueTypes can also be a list of
    # types separated by commas."
    it 'parses multiple key/value types in hash parameters' do
      types = Solargraph::ComplexType.parse('Hash{String, Symbol => Integer, BigDecimal}')
      expect(types.length).to eq(1)
      type = types.first
      expect(type.hash_parameters?).to eq(true)
      expect(type.key_types.map(&:name)).to eq(%w[String Symbol])
      expect(type.value_types.map(&:name)).to eq(%w[Integer BigDecimal])
      expect(type.to_rbs).to eq('Hash[(String | Symbol), (Integer | BigDecimal)]')
    end

    #
    # Order-Dependent Lists
    #

    # An order dependent list is a set of types surrounded by "()" and
    # separated by commas. This list must contain exactly those types in
    # exactly the order specified. For instance, an Array containing a
    # String, Fixnum and Hash in that order (and having exactly those 3
    # elements) would be listed as: Array(String, Fixnum, Hash).

    it 'parses tuples of tuples' do
      type = Solargraph::ComplexType.parse('Array(Array(String), String)')
      expect(type.tag).to eq('Array(Array(String), String)')
      expect(type.to_rbs).to eq('[[String], String]')
      expect(type.to_s).to eq('Array(Array(String), String)')
    end

    # Literals
    #
    # Some literals are accepted by virtue of being Ruby literals, but
    # also by YARD conventions. Here is a non-exhaustive list of certain
    # accepted literal values:

    # true, false, nil — used when a method returns these explicit
    # literal values. Note that if your method returns both true or
    # false, you should use the Boolean conventional type instead.

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

    # See literal details at
    # https://github.com/ruby/rbs/blob/master/docs/syntax.md and
    # https://yardoc.org/types.html
    it 'understands literal strings with double quotes' do
      pending('string escaping support being added')

      type = Solargraph::ComplexType.parse('"foo"')
      expect(type.tag).to eq('"foo"')
      expect(type.to_rbs).to eq('"foo"')
      expect(type.to_s).to eq('String')
    end

    it 'understands literal strings with single quotes' do
      pending('string escaping support being added')

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

    #
    # self — has the same meaning as Ruby's "self" keyword in the
    # context of parameters or return types. Recommended mostly for
    # @return tags that are chainable.
    #

    it 'parses a complex subtype as a self type' do
      type = Solargraph::ComplexType.parse('Array<self>').self_to_type(Solargraph::ComplexType.parse('Foo<String>'))
      expect(type.tag).to eq('Array<Foo<String>>')
      expect(type.to_rbs).to eq('Array[Foo[String]]')
    end

    # void — indicates that the type for this tag is explicitly
    # undefined. Mostly used to specify @return tags that do not care
    # about their return value. Using a void return tag is recommended
    # over no type, because it makes the documentation more explicit
    # about what the user should expect. YARD will also add a note for
    # the user if they have undefined return types, making things clear
    # that they should not use the return value of such a method.
    #
    # Reference Tags
    #
    #
    # Reference tag syntax applies only to meta-data tags, not directives.
    #
    # If a tag's data begins with (see OBJECT) it is considered a
    # "reference tag". A reference tag literally copies the tag data by
    # the given tag name from the specified OBJECT. For instance, a
    # method may copy all @param tags from a given object using the
    # reference tag syntax:
    #
    # # @param user [String] the username for the operation
    # # @param host [String] the host that this user is associated with
    # # @param time [Time] the time that this operation took place
    # def clean(user, host, time = Time.now) end
    #
    # # @param (see #clean)
    # def activate(user, host, time = Time.now) end
    #
    xit 'understands reference tags'
  end

  context 'when given non-sensical types by machine users' do
    it 'raises ComplexTypeError for unmatched brackets' do
      expect do
        Solargraph::ComplexType.parse('Array<String')
      end.to raise_error(Solargraph::ComplexTypeError)
      expect do
        Solargraph::ComplexType.parse('Array{String')
      end.to raise_error(Solargraph::ComplexTypeError)
      expect do
        Solargraph::ComplexType.parse('Array<String>>')
      end.to raise_error(Solargraph::ComplexTypeError)
      expect do
        Solargraph::ComplexType.parse('Array{String}}')
      end.to raise_error(Solargraph::ComplexTypeError)
      expect do
        Solargraph::ComplexType.parse('Array(String, Integer')
      end.to raise_error(Solargraph::ComplexTypeError)
      expect do
        Solargraph::ComplexType.parse('Array(String, Integer))')
      end.to raise_error(Solargraph::ComplexTypeError)
    end

    it 'raises ComplexTypeError for hash parameters without key => value syntax' do
      expect do
        Solargraph::ComplexType.parse('Hash{Foo}')
      end.to raise_error(Solargraph::ComplexTypeError)
      expect do
        Solargraph::ComplexType.parse('Hash{Foo, Bar}')
      end.to raise_error(Solargraph::ComplexTypeError)
    end
  end

  context 'when offering type queries orthogonal to YARD spec' do
    context 'when defining namespace concept which strips Class<> and Module<> from type' do
      #
      # Solargraph extensions and library features
      #

      it 'detects namespace and scope for simple types' do
        types = Solargraph::ComplexType.parse 'Class'
        expect(types.length).to eq(1)
        expect(types.first.namespace).to eq('Class')
        expect(types.first.scope).to eq(:instance)
        expect(types.to_rbs).to eq('Class')
      end

      it 'detects namespace and scope for classes with subtypes' do
        types = Solargraph::ComplexType.parse 'Class<String>'
        expect(types.length).to eq(1)
        expect(types.first.namespace).to eq('String')
        expect(types.first.scope).to eq(:class)
        # RBS doesn't support individual class types like this
        expect(types.to_rbs).to eq('Class')
      end

      it 'detects namespace and scope for modules with subtypes' do
        types = Solargraph::ComplexType.parse 'Module<Foo>'
        expect(types.length).to eq(1)
        expect(types.first.namespace).to eq('Foo')
        expect(types.first.scope).to eq(:class)
        expect(types.to_rbs).to eq('Module')
        multiple_types = Solargraph::ComplexType.parse 'Module<Foo>, Class<Bar>, String, nil'
        expect(multiple_types.length).to eq(4)
        expect(multiple_types.namespaces).to eq(%w[Foo Bar String NilClass])
        # RBS doesn't support individual module types like this
        expect(multiple_types.to_rbs).to eq('(Module | Class | String | nil)')
      end
    end

    context 'when simplifying type representation on output' do
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
        type = type.qualify(api_map, '')
        expect(type.to_s).to eq('1, 2, 3')
        expect(type.tags).to eq('1, 2, 3')
        expect(type.simple_tags).to eq('Integer')
        expect(type.to_rbs).to eq('(1 | 2 | 3)')
      end
    end

    it 'identifies nil types regardless of capitalization' do
      %w[nil Nil NIL].each do |t|
        types = Solargraph::ComplexType.parse(t)
        expect(types.length).to eq(1)
        expect(types.first.namespace).to eq('NilClass')
        expect(types.first.scope).to eq(:instance)
        expect(types.first.nil_type?).to be(true)
        expect(types.to_rbs).to eq('nil')
      end
    end

    context 'when defining rooted and unrooted concept' do
      it 'identify rooted types' do
        types = Solargraph::ComplexType.parse '::Array'
        expect(types.map(&:rooted?)).to eq([true])
        expect(types.to_rbs).to eq('::Array')
      end

      it 'identify unrooted types' do
        types = Solargraph::ComplexType.parse 'Array'
        expect(types.map(&:rooted?)).to eq([false])
      end

      ['generic<T>', 'nil', 'true', 'false', ':123', '123'].each do |tag|
        it "treats #{tag} as rooted" do
          types = Solargraph::ComplexType.parse(tag)
          expect(types.all?(&:rooted?)).to be(true)
        end
      end
    end

    context 'when allowing users to define their own generic types' do
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
        generic_class = Solargraph::Pin::Namespace.new(name: 'Foo',
                                                       comments: "@generic GenericTypeParam1\n@generic GenericTypeParam2")
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
        generic_class = Solargraph::Pin::Namespace.new(name: 'Foo',
                                                       comments: "@generic GenericTypeParam1\n@generic GenericTypeParam2")
        called_method = Solargraph::Pin::Method.new(
          location: Solargraph::Location.new('file:///foo.rb', Solargraph::Range.from_to(0, 0, 0, 0)),
          closure: generic_class,
          name: 'bar',
          comments: '@return [Foo<String, Integer>]'
        )
        type = return_type.resolve_generics(generic_class, called_method.return_type)
        expect(type.tag).to eq('Array<(String, Integer)>')
      end

      UNIQUE_METHOD_GENERIC_TESTS = [
        # tag, context_type_tag, unfrozen_input_map, expected_tag, expected_output_map
        ['String', 'String', {}, 'String', {}],
        ['generic<A>', 'String', {}, 'String', { 'A' => 'String' }],
        ['generic<A>', 'Array<String>', {}, 'Array<String>', { 'A' => 'Array<String>' }],
        ['generic<A>', 'Array<String>', { 'A' => 'String' }, 'String', { 'A' => 'String' }],
        ['generic<A>', 'Array<generic<B>>', { 'B' => 'Integer' }, 'Array<Integer>',
         { 'B' => 'Integer', 'A' => 'Array<Integer>' }],
        ['Array<generic<A>>', 'Array<String>', {}, 'Array<String>', { 'A' => 'String' }]
      ]

      UNIQUE_METHOD_GENERIC_TESTS.each do |tag, context_type_tag, unfrozen_input_map, expected_tag, expected_output_map|
        context "when resolveing #{tag} with context #{context_type_tag} and existing resolved generics #{unfrozen_input_map}" do
          let(:complex_type) { Solargraph::ComplexType.parse(tag) }
          let(:unique_type) { complex_type.first }

          it '#{tag} is a unique type' do
            expect(complex_type.length).to eq(1)
          end

          let(:generic_value) { unfrozen_input_map.transform_values! { |tag| Solargraph::ComplexType.parse(tag) } }
          let(:context_type) { Solargraph::ComplexType.parse(context_type_tag) }

          it "resolves to #{expected_tag} with updated map #{expected_output_map}" do
            resolved_generic_values = unfrozen_input_map.transform_values { |tag| Solargraph::ComplexType.parse(tag) }
            resolved_type = unique_type.resolve_generics_from_context(expected_output_map.keys, context_type,
                                                                      resolved_generic_values: resolved_generic_values)
            expect(resolved_type.tag).to eq(expected_tag)
            expect(resolved_generic_values.transform_values(&:tag)).to eq(expected_output_map)
          end
        end
      end
    end
  end

  context 'when identifying type of parameter syntax used' do
    it 'raises NoMethodError for missing methods' do
      type = Solargraph::ComplexType.parse('String')
      expect { type.undefined_method }.to raise_error(NoMethodError)
    end

    it 'identifies list parameter types' do
      types = Solargraph::ComplexType.parse('Array<String, Symbol>')
      expect(types.first.list_parameters?).to be(true)
      expect(types.to_rbs).to eq('Array[String, Symbol]')
    end

    it 'identifies fixed parameters' do
      types = Solargraph::ComplexType.parse('Array(String, Symbol)')
      expect(types.first.fixed_parameters?).to be(true)
      expect(types.first.subtypes.map(&:namespace)).to eq(%w[String Symbol])
      # RBS doesn't use a type name for tuples, just the [] shorthand
      expect(types.to_rbs).to eq('[String, Symbol]')
    end

    it 'identifies hash parameters' do
      types = Solargraph::ComplexType.parse('Hash{String => Integer}')
      expect(types.length).to eq(1)
      expect(types.first.hash_parameters?).to be(true)
    end
  end

  context "when 'qualifying' types by resolving relative references to types to absolute references (fully qualified types)" do
    it 'returns undefined for unqualified types' do
      api_map = instance_double(Solargraph::ApiMap, qualify: nil)
      type = Solargraph::ComplexType.parse('UndefinedClass')
      qualified = type.qualify(api_map)
      expect(qualified).to be_undefined
      expect(qualified.to_rbs).to eq('untyped')
    end
  end

  context 'when allowing list-of-types to be destructively cast down to a single type' do
    it 'returns the first type when multiple were parsed with #tag' do
      type = Solargraph::ComplexType.parse('String, Array<String>')
      expect(type.tag).to eq('String')
      expect(type.to_rbs).to eq('(String | Array[String])')
    end
  end

  context "when supporting arbitrary combinations of the above syntax and features" do
    it 'returns string representations of the entire type array' do
      type = Solargraph::ComplexType.parse('String', 'Array<String>')
      expect(type.to_s).to eq('String, Array<String>')
      # we want this surrounded by () so that it can be composed with
      # other types without worrying about operator precedence
      expect(type.to_rbs).to eq('(String | Array[String])')
    end

    it 'parses recursive subtypes' do
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

    it 'allows various parameterized types as parameterized type' do
      types = Solargraph::ComplexType.parse('Array<String>, Hash{String => Symbol}, Array(String, Integer)')
      expect(types.all?(&:parameters?)).to be(true)
      expect(types.to_rbs).to eq('(Array[String] | Hash[String, Symbol] | [String, Integer])')
    end

    let(:foo_bar_api_map) do
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
    end

    it 'qualifies types with list parameters' do
      original = Solargraph::ComplexType.parse('Class<Bar>').first
      expect(original).not_to be_rooted
      qualified = original.qualify(foo_bar_api_map, 'Foo')
      expect(qualified.tag).to eq('Class<Foo::Bar>')
      expect(qualified.rooted_tag).to eq('::Class<::Foo::Bar>')
      expect(qualified).to be_rooted
      expect(qualified.to_rbs).to eq('::Class')
    end

    it 'qualifies types with fixed parameters' do
      original = Solargraph::ComplexType.parse('Array(String, Bar)').first
      expect(original.to_rbs).to eq('[String, Bar]')
      qualified = original.qualify(foo_bar_api_map, 'Foo')
      expect(qualified).to be_rooted
      expect(qualified.tag).to eq('Array(String, Foo::Bar)')
      expect(qualified.to_rbs).to eq('[::String, ::Foo::Bar]')
    end

    it 'qualifies types with hash parameters' do
      original = Solargraph::ComplexType.parse('Hash{String => Bar}').first
      qualified = original.qualify(foo_bar_api_map, 'Foo')
      expect(qualified.tag).to eq('Hash{String => Foo::Bar}')
      expect(qualified.to_rbs).to eq('::Hash[::String, ::Foo::Bar]')
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

    it 'qualifies special types' do
      api_map = Solargraph::ApiMap.new
      type = Solargraph::ComplexType.parse('nil')
      qual = type.qualify(api_map)
      expect(qual.tag).to eq('nil')
      expect(qual.to_rbs).to eq('nil')
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

    it 'understands self types as subtypes' do
      api_map = Solargraph::ApiMap.new
      selfy = Solargraph::ComplexType.parse('Array<self>')
      type = selfy.self_to_type(Solargraph::ComplexType.parse('String'))
      expect(type.tag).to eq('Array<String>')
      expect(type.to_rbs).to eq('Array[String]')
      result = type.qualify(api_map)
      expect(result.tag).to eq('Array<String>')
      expect(result.to_rbs).to eq('::Array[::String]')
    end

    it 'stops parsing when the first character indicates a string literal' do
      pending('string escaping support being added')

      api_map = Solargraph::ApiMap.new
      type = Solargraph::ComplexType.parse('"Array(Symbol, String, Array(Integer, Integer)"')
      type = type.qualify(api_map)
      expect(type.tag).to eq('Array(Symbol, String, Array(Integer, Integer))')
      expect(type.to_rbs).to eq('[Symbol, String, [Integer, Integer]]')
      expect(type.to_s).to eq('Array(Symbol, String, Array(Integer, Integer))')
    end

    it 'recognizes String conforms with itself' do
      api_map = Solargraph::ApiMap.new
      ptype = Solargraph::ComplexType.parse('String')
      atype = Solargraph::ComplexType.parse('String')
      expect(atype.conforms_to?(api_map, ptype, :method_call)).to be(true)
    end

    it 'recognizes an erased container type conforms with itself' do
      api_map = Solargraph::ApiMap.new
      ptype = Solargraph::ComplexType.parse('Hash')
      atype = Solargraph::ComplexType.parse('Hash')
      expect(atype.conforms_to?(api_map, ptype, :method_call)).to be(true)
    end

    it 'recognizes an unerased container type conforms with itself' do
      api_map = Solargraph::ApiMap.new
      ptype = Solargraph::ComplexType.parse('Array<Integer>')
      atype = Solargraph::ComplexType.parse('Array<Integer>')
      expect(atype.conforms_to?(api_map, ptype, :method_call)).to be(true)
    end

    it 'recognizes a literal conforms with its type' do
      api_map = Solargraph::ApiMap.new
      ptype = Solargraph::ComplexType.parse('Symbol')
      atype = Solargraph::ComplexType.parse(':foo')
      expect(atype.conforms_to?(api_map, ptype, :method_call)).to be(true)
    end
  end
end
