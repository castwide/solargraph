require 'tmpdir'

describe Solargraph::ApiMap do
  before :all do
    @api_map = Solargraph::ApiMap.new
  end

  it 'returns core methods' do
    pins = @api_map.get_methods('String')
    expect(pins.map(&:path)).to include('String#upcase')
  end

  it 'returns core classes' do
    pins = @api_map.get_constants('')
    expect(pins.map(&:path)).to include('String')
  end

  it 'indexes pins' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar
        end
      end
    ))
    @api_map.index map.pins
    pins = @api_map.get_path_pins('Foo#bar')
    expect(pins.length).to eq(1)
    expect(pins.first.path).to eq('Foo#bar')
  end

  it 'finds methods from included modules' do
    map = Solargraph::SourceMap.load_string(%(
      module Mixin
        def mix_method
        end
      end
      class Foo
        include Mixin
        def bar
        end
      end
    ))
    @api_map.index map.pins
    pins = @api_map.get_methods('Foo')
    expect(pins.map(&:path)).to include('Mixin#mix_method')
  end

  it 'finds methods from superclasses' do
    map = Solargraph::SourceMap.load_string(%(
      class Sup
        def sup_method
        end
      end
      class Sub < Sup
      end
    ))
    @api_map.index map.pins
    pins = @api_map.get_methods('Sub')
    expect(pins.map(&:path)).to include('Sup#sup_method')
  end

  it 'checks method pin visibility' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        private
        def bar
        end
      end
    ))
    @api_map.index map.pins
    pins = @api_map.get_methods('Foo')
    expect(pins.map(&:path)).not_to include('Foo#bar')
  end

  it 'checks method pin private visibility set by yard directive' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        # @!visibility private
        def bar
        end
      end
    ))
    @api_map.index map.pins
    pins = @api_map.get_methods('Foo')
    expect(pins.map(&:path)).not_to include('Foo#bar')
  end

  it 'checks method pin protected visibility set by yard directive' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        # @!visibility protected
        def bar
        end
      end
    ))
    @api_map.index map.pins
    pins = @api_map.get_methods('Foo')
    expect(pins.map(&:path)).not_to include('Foo#bar')
  end

  it 'finds nested namespaces' do
    map = Solargraph::SourceMap.load_string(%(
      module Foo
        class Bar
        end
        class Baz
        end
      end
    ))
    @api_map.index map.pins
    pins = @api_map.get_constants('Foo')
    paths = pins.map(&:path)
    expect(paths).to include('Foo::Bar')
    expect(paths).to include('Foo::Baz')
  end

  it 'finds nested namespaces within a context' do
    map = Solargraph::SourceMap.load_string(%(
      module Foo
        class Bar
          BAR_CONSTANT = 'bar'
        end
        class Baz
        end
      end
    ))
    @api_map.index map.pins
    pins = @api_map.get_constants('Bar', 'Foo')
    expect(pins.map(&:path)).to include('Foo::Bar::BAR_CONSTANT')
  end

  it 'checks constant visibility' do
    map = Solargraph::SourceMap.load_string(%(
      module Foo
        FOO_CONSTANT = 'foo'
        private_constant :FOO_CONSTANT
      end
    ))
    @api_map.index map.pins
    pins = @api_map.get_constants('Foo', '')
    expect(pins.map(&:path)).not_to include('Foo::FOO_CONSTANT')
    pins = @api_map.get_constants('', 'Foo')
    expect(pins.map(&:path)).to include('Foo::FOO_CONSTANT')
  end

  it 'includes Kernel methods in the root namespace' do
    @api_map.index []
    pins = @api_map.get_methods('', visibility: [:private])
    expect(pins.map(&:path)).to include('Kernel#puts')
  end

  it 'gets instance methods for complex types' do
    @api_map.index []
    type = Solargraph::ComplexType.parse('String')
    pins = @api_map.get_complex_type_methods(type)
    expect(pins.map(&:path)).to include('String#upcase')
  end

  it 'gets class methods for complex types' do
    @api_map.index []
    type = Solargraph::ComplexType.parse('Class<String>')
    pins = @api_map.get_complex_type_methods(type)
    expect(pins.map(&:path)).to include('String.try_convert')
  end

  it 'checks visibility of complex type methods' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        private
        def priv
        end
        protected
        def prot
        end
      end
    ))
    @api_map.index map.pins
    type = Solargraph::ComplexType.parse('Foo')
    pins = @api_map.get_complex_type_methods(type, 'Foo')
    expect(pins.map(&:path)).to include('Foo#prot')
    expect(pins.map(&:path)).not_to include('Foo#priv')
    pins = @api_map.get_complex_type_methods(type, 'Foo', true)
    expect(pins.map(&:path)).to include('Foo#prot')
    expect(pins.map(&:path)).to include('Foo#priv')
  end

  it 'finds methods for duck types' do
    @api_map.index []
    type = Solargraph::ComplexType.parse('#foo, #bar')
    pins = @api_map.get_complex_type_methods(type)
    expect(pins.map(&:name)).to include('foo')
    expect(pins.map(&:name)).to include('bar')
  end

  it 'adds Object instance methods to duck types' do
    api_map = Solargraph::ApiMap.new
    type = Solargraph::ComplexType.parse('#foo')
    pins = api_map.get_complex_type_methods(type)
    expect(pins.any? { |p| p.namespace == 'BasicObject' }).to be(true)
  end

  it 'finds methods for parametrized class types' do
    @api_map.index []
    type = Solargraph::ComplexType.parse('Class<String>')
    pins = @api_map.get_complex_type_methods(type)
    expect(pins.map(&:path)).to include('String.try_convert')
  end

  it 'finds stacks of methods' do
    map = Solargraph::SourceMap.load_string(%(
      module Mixin
        def meth; end
      end
      class Foo
        include Mixin
        def meth; end
      end
      class Bar < Foo
        def meth; end
      end
    ))
    @api_map.index map.pins
    pins = @api_map.get_method_stack('Bar', 'meth')
    expect(pins.map(&:path)).to eq(['Bar#meth', 'Foo#meth', 'Mixin#meth'])
  end

  it 'finds symbols' do
    map = Solargraph::SourceMap.load_string('sym = :sym')
    @api_map.index map.pins
    pins = @api_map.get_symbols
    expect(pins.map(&:name)).to include(':sym')
  end

  it 'finds instance variables' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        @cvar = ''
        def bar
          @ivar = ''
        end
      end
    ))
    @api_map.index map.pins
    pins = @api_map.get_instance_variable_pins('Foo', :instance)
    expect(pins.map(&:name)).to include('@ivar')
    expect(pins.map(&:name)).not_to include('@cvar')
    pins = @api_map.get_instance_variable_pins('Foo', :class)
    expect(pins.map(&:name)).not_to include('@ivar')
    expect(pins.map(&:name)).to include('@cvar')
  end

  it 'finds class variables' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        @@cvar = make_value
      end
    ))
    @api_map.index map.pins
    pins = @api_map.get_class_variable_pins('Foo')
    expect(pins.map(&:name)).to include('@@cvar')
  end

  it 'finds global variables' do
    map = Solargraph::SourceMap.load_string('$foo = []')
    @api_map.index map.pins
    pins = @api_map.get_global_variable_pins
    expect(pins.map(&:name)).to include('$foo')
  end

  it 'generates clips' do
    source = Solargraph::Source.load_string(%(
      class Foo
        def bar; end
      end
      Foo.new.bar
    ), 'my_file.rb')
    @api_map.map source
    clip = @api_map.clip_at('my_file.rb', Solargraph::Position.new(4, 15))
    expect(clip).to be_a(Solargraph::SourceMap::Clip)
  end

  it 'searches the Ruby core' do
    @api_map.index []
    results = @api_map.search('Array#len')
    expect(results).to include('Array#length')
  end

  it 'documents the Ruby core' do
    @api_map.index []
    docs = @api_map.document('Array')
    expect(docs).not_to be_empty
    expect(docs.map(&:path).uniq).to eq(['Array'])
  end

  it 'catalogs changes' do
    Solargraph::Workspace.new
    s1 = Solargraph::SourceMap.load_string('class Foo; end')
    @api_map.catalog(Solargraph::Bench.new(source_maps: [s1]))
    expect(@api_map.get_path_pins('Foo')).not_to be_empty
    s2 = Solargraph::SourceMap.load_string('class Bar; end')
    @api_map.catalog(Solargraph::Bench.new(source_maps: [s2]))
    expect(@api_map.get_path_pins('Foo')).to be_empty
    expect(@api_map.get_path_pins('Bar')).not_to be_empty
  end

  it 'checks attribute visibility' do
    source = Solargraph::Source.load_string(%(
      class Foo
        attr_reader :public_attr
        private
        attr_reader :private_attr
      end
    ))
    @api_map.map source
    pins = @api_map.get_methods('Foo')
    paths = pins.map(&:path)
    expect(paths).to include('Foo#public_attr')
    expect(paths).not_to include('Foo#private_attr')
    pins = @api_map.get_methods('Foo', visibility: [:private])
    paths = pins.map(&:path)
    expect(paths).not_to include('Foo#public_attr')
    expect(paths).to include('Foo#private_attr')
  end

  it 'resolves superclasses qualified with leading colons' do
    code = %(
      class Sup
        def bar; end
      end
      module Foo
        class Sup < ::Sup; end
        class Sub < Sup
          def bar; end
        end
      end
      )
    source = Solargraph::Source.load_string(code)
    @api_map.map source
    pins = @api_map.get_methods('Foo::Sub')
    paths = pins.map(&:path)
    expect(paths).to include('Foo::Sub#bar')
    expect(paths).to include('Sup#bar')
  end

  it 'finds protected methods for complex types' do
    code = %(
      class Sup
        protected
        def bar; end
      end
      class Sub < Sup; end
      class Sub2 < Sub; end
    )
    source = Solargraph::Source.load_string(code)
    @api_map.map source
    pins = @api_map.get_complex_type_methods(Solargraph::ComplexType.parse('Sub'), 'Sub')
    expect(pins.map(&:path)).to include('Sup#bar')
    pins = @api_map.get_complex_type_methods(Solargraph::ComplexType.parse('Sub2'), 'Sub2')
    expect(pins.map(&:path)).to include('Sup#bar')
    pins = @api_map.get_complex_type_methods(Solargraph::ComplexType.parse('Sup'), 'Sub')
    expect(pins.map(&:path)).to include('Sup#bar')
    pins = @api_map.get_complex_type_methods(Solargraph::ComplexType.parse('Sup'), 'Sub2')
    expect(pins.map(&:path)).to include('Sup#bar')
  end

  it 'ignores undefined superclasses when finding complex type methods' do
    code = %(
      class Sub < Sup; end
      class Sub2 < Sub; end
    )
    source = Solargraph::Source.load_string(code)
    @api_map.map source
    expect do
      @api_map.get_complex_type_methods(Solargraph::ComplexType.parse('Sub'), 'Sub2')
    end.not_to raise_error
  end

  it 'detects private constants according to context' do
    code = %(
      class Foo
        class Bar; end
        private_constant :Bar
      end
    )
    source = Solargraph::Source.load_string(code)
    @api_map.map source
    pins = @api_map.get_constants('Foo', '')
    expect(pins.map(&:path)).not_to include('Bar')
    pins = @api_map.get_constants('Foo', 'Foo')
    expect(pins.map(&:path)).to include('Foo::Bar')
  end

  it 'catalogs requires' do
    source1 = Solargraph::SourceMap.load_string(%(
      class Foo; end
    ), 'lib/foo.rb')
    source2 = Solargraph::SourceMap.load_string(%(
      require 'foo'
      require 'invalid'
    ), 'app.rb')
    @api_map.catalog Solargraph::Bench.new(source_maps: [source1, source2], external_requires: ['invalid'])
    expect(@api_map.unresolved_requires).to eq(['invalid'] + @api_map.doc_map.environ.requires)
  end

  it 'gets instance variables from superclasses' do
    source = Solargraph::Source.load_string(%(
      class Sup
        def foo
          @foo = 'foo'
        end
      end
      class Sub < Sup; end
    ))
    @api_map.map source
    pins = @api_map.get_instance_variable_pins('Sub')
    expect(pins.map(&:name)).to include('@foo')
  end

  it 'gets methods from extended modules' do
    source = Solargraph::Source.load_string(%(
      module Mixin
        def bar; end
      end
      class Sup
        extend Mixin
      end
    ))
    @api_map.map source
    pins = @api_map.get_methods('Sup', scope: :class)
    expect(pins.map(&:path)).to include('Mixin#bar')
  end

  it 'loads workspaces from directories' do
    api_map = Solargraph::ApiMap.load('spec/fixtures/workspace')
    expect(api_map.source_map(File.absolute_path('spec/fixtures/workspace/app.rb'))).to be_a(Solargraph::SourceMap)
  end

  it 'finds constants from included modules' do
    source = Solargraph::Source.load_string(%(
      module Mixin
        FOO = 'foo'
      end
      class Container
        include Mixin
      end
    ))
    @api_map.map source
    pins = @api_map.get_constants('Container')
    expect(pins.map(&:path)).to include('Mixin::FOO')
  end

  it 'sorts constants by name' do
    source = Solargraph::Source.load_string(%(
      module Foo
        AAB = 'aaa'
        class AAA; end
      end
    ))
    @api_map.map source
    pins = @api_map.get_constants('Foo', '')
    expect(pins.length).to eq(2)
    expect(pins[0].name).to eq('AAA')
    expect(pins[1].name).to eq('AAB')
  end

  it 'returns one pin for root methods' do
    source = Solargraph::Source.load_string(%(
      def sum1(a, b)
      end
      sum1()
    ), 'test.rb')
    @api_map.map source
    pins = @api_map.get_method_stack('', 'sum1')
    expect(pins.length).to eq(1)
    expect(pins.map(&:name)).to include('sum1')
  end

  it 'detects method aliases with origins in other sources' do
    source1 = Solargraph::SourceMap.load_string(%(
      class Sup
        # @return [String]
        def foo; end
      end
    ), 'source1.rb')
    source2 = Solargraph::SourceMap.load_string(%(
      class Sub < Sup
        alias bar foo
      end
    ), 'source2.rb')
    @api_map.catalog Solargraph::Bench.new(source_maps: [source1, source2])
    pin = @api_map.get_path_pins('Sub#bar').first
    expect(pin).not_to be_nil
    expect(pin.return_type.tag).to eq('String')
  end

  it 'finds extended module methods' do
    source = Solargraph::Source.load_string(%(
      module MyModule
        def foo; end
      end
      module MyClass
        extend MyModule
      end
      ), 'test.rb')
    @api_map.map source
    pins = @api_map.get_methods('MyClass', scope: :class)
    expect(pins.map(&:path)).to include('MyModule#foo')
  end

  it 'qualifies namespaces from includes' do
    source = Solargraph::Source.load_string(%(
      module Foo
        class Bar; end
      end
      module Includer
        include Foo
      end
    ))
    @api_map.map source
    fqns = @api_map.qualify('Bar', 'Includer')
    expect(fqns).to eq('Foo::Bar')
  end

  it 'handles multiple type parameters without losing cache coherence' do
    tag = @api_map.qualify('Array<String>')
    expect(tag).to eq('Array<String>')
    tag = @api_map.qualify('Array<Integer>')
    expect(tag).to eq('Array<Integer>')
  end

  it 'handles multiple type parameters without losing cache coherence' do
    tag = @api_map.qualify('Hash{Integer => String}')
    expect(tag).to eq('Hash{Integer => String}')
  end

  it 'qualifies namespaces with conflicting includes' do
    source = Solargraph::Source.load_string(%(
      module Bar; end
      module Foo
        module Bar; end
      end
      module Foo
        module Includer
          include Bar
        end
      end
    ))
    @api_map.map source
    fqns = @api_map.qualify('Bar', 'Foo::Includer')
    expect(fqns).to eq('Foo::Bar')
  end

  it 'qualifies namespaces from root includes' do
    source = Solargraph::Source.load_string(%(
      module A
        module B
          module C
            def self.foo; end
          end
        end
      end

      include A
      B::C
    ), 'test.rb')
    @api_map.map source
    fqns = @api_map.qualify('B::C', '')
    expect(fqns).to eq('A::B::C')
  end

  it 'finds methods for classes that override constant assignments' do
    source = Solargraph::Source.load_string(%(
      class Foo
        Bar = String
        class Bar
          def baz; end
        end
      end
    ))
    @api_map.map source
    paths = @api_map.get_methods('Foo::Bar').map(&:path)
    expect(paths).to include('Foo::Bar#baz')
  end

  it 'sets method alias visibility' do
    source = Solargraph::Source.load_string(%(
      class Foo
        private
        def bar; end
        alias baz bar
      end
    ))
    @api_map.map source
    pins = @api_map.get_methods('Foo', visibility: %i[public private])
    baz = pins.select { |pin| pin.name == 'baz' }.first
    expect(baz.visibility).to be(:private)
  end

  it 'finds constants in superclasses' do
    source = Solargraph::Source.load_string(%(
      class Foo
        Bar = 42
      end

      class Baz < Foo; end
    ))
    @api_map.map source
    pins = @api_map.get_constants('Baz')
    expect(pins.map(&:path)).to include('Foo::Bar')
  end

  it 'qualifies superclasses with same name as subclass' do
    source = Solargraph::Source.load_string(%(
      class Foo; end
      class Bar; end
      class Bar::Foo < Foo; end
    ))
    @api_map.map source
    expect(@api_map.super_and_sub?('Foo', 'Bar::Foo')).to be(true)
  end

  it 'avoids circular references in super_and_sub? tests' do
    source = Solargraph::Source.load_string(%(
      class Foo < Bar; end
      class Bar < Bar; end
    ))
    @api_map.map source
    expect(@api_map.super_and_sub?('Foo', 'Bar')).to be(false)
  end

  it 'adds prepended methods to the ancestor tree' do
    source = Solargraph::Source.load_string(%(
      module Prepended
        def foo; end
      end
      module Included
        def foo; end
      end
      class Container
        include Included
        prepend Prepended
        def foo; end
      end
    ))
    @api_map.map source
    pins = @api_map.get_method_stack('Container', 'foo')
    paths = pins.map(&:path)
    expect(paths).to eq(['Prepended#foo', 'Container#foo', 'Included#foo'])
  end

  it 'adds prepended constants' do
    source = Solargraph::Source.load_string(%(
      module Prepended
        PRE_CONST = 'pre_const'
      end
      class Container
        prepend Prepended
      end
    ))
    @api_map.map source
    pins = @api_map.get_constants('Container')
    paths = pins.map(&:path)
    expect(paths).to eq(['Prepended::PRE_CONST'])
  end

  # @todo This test fails with lazy dynamic rebinding
  xit 'finds instance variables in yieldreceiver blocks' do
    source = Solargraph::Source.load_string(%(
      module Container
        # @yieldreceiver [Container]
        def self.inside &block; end
      end

      Container.inside do
        @var1 = 1
      end

      Container.inside do
        @var2 = 2
      end

      @var3 = 3
    ), 'test.rb')
    @api_map.map source
    vars = @api_map.get_instance_variable_pins('Container')
    names = vars.map(&:name)
    expect(names).to include('@var1')
    expect(names).to include('@var2')
    expect(names).not_to include('@var3')
  end

  it 'finds class methods from modules included from class << self' do
    source = Solargraph::Source.load_string(%(
      module Extender
        def foo; end
      end

      class Example
        class << self
          include Extender
        end
      end
    ))
    @api_map.map source
    pins = @api_map.get_methods('Example', scope: :class)
    expect(pins.map(&:name)).to include('foo')
  end

  it 'finds class methods in class << Example' do
    source = Solargraph::Source.load_string(%(
      class << Example = Class.new
        def foo; end
      end
      class Example
        class << Example
          def bar; end
        end
      end
    ))
    @api_map.map source
    pins = @api_map.get_methods('Example', scope: :class).select do |pin|
      pin.namespace == 'Example'
    end
    expect(pins.map(&:name).sort).to eq(%w[bar foo])
  end

  it 'finds class methods in nested class << Example' do
    source = Solargraph::Source.load_string(%(
      module Container
        class << Example = Class.new
          def foo; end
        end
        class Example
          class << Example
            def bar; end
          end
        end
      end
    ))
    @api_map.map source
    pins = @api_map.get_methods('Container::Example', scope: :class).select do |pin|
      pin.namespace == 'Container::Example'
    end
    expect(pins.map(&:name).sort).to eq(%w[bar foo])
  end

  it 'resolves aliases for YARD methods' do
    dir = File.absolute_path(File.join('spec', 'fixtures', 'yard_map'))
    yard_pins = Dir.chdir dir do
      YARD::Registry.load([File.join(dir, 'attr.rb')], true)
      mapper = Solargraph::YardMap::Mapper.new(YARD::Registry.all)
      mapper.map
    end
    source_pins = Solargraph::SourceMap.load_string(%(
      class Foo
        alias baz foo
      end
    )).pins
    # api_map = Solargraph::ApiMap.new(pins: yard_pins + source_pins)
    @api_map.index yard_pins + source_pins
    baz = @api_map.get_method_stack('Foo', 'baz').first
    expect(baz).to be_a(Solargraph::Pin::Method)
    expect(baz.path).to eq('Foo#baz')
  end

  it 'ignores malformed mixins' do
    closure = Solargraph::Pin::Namespace.new(name: 'Foo', closure: Solargraph::Pin::ROOT_PIN, type: :class)
    mixin = Solargraph::Pin::Reference::Include.new(name: 'defined?(DidYouMean::SpellChecker) && defined?(DidYouMean::Correctable)', closure: closure)
    api_map = Solargraph::ApiMap.new(pins: [closure, mixin])
    expect(api_map.get_method_stack('Foo', 'foo')).to be_empty
  end
end
