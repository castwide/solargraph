describe Solargraph::SourceMap::Mapper do
  it "creates `new` pins for `initialize` pins" do
    source = Solargraph::Source.new(%(
      class Foo
        def initialize; end
      end

      class Foo::Bar
        def initialize; end
      end
    ))
    map = Solargraph::SourceMap.map(source)
    foo_pin = map.pins.select{|pin| pin.path == 'Foo.new'}.first
    expect(foo_pin.return_type.tag).to eq('self')
    bar_pin = map.pins.select{|pin| pin.path == 'Foo::Bar.new'}.first
    expect(bar_pin.return_type.tag).to eq('self')
  end

  it "ignores include calls that are not attached to the current namespace" do
    source = Solargraph::Source.new(%(
      class Foo
        include Direct
        xyz.include Indirect
        xyz(include Interior)
      end
    ))
    map = Solargraph::SourceMap.map(source)
    pins = map.pins.select{|pin| pin.is_a?(Solargraph::Pin::Reference::Include) && pin.namespace == 'Foo'}
    names = pins.map(&:name)
    expect(names).to include('Direct')
    expect(names).not_to include('Indirect')
    expect(names).to include('Interior')
  end

  it "ignores prepend calls that are not attached to the current namespace" do
    source = Solargraph::Source.new(%(
      class Foo
        prepend Direct
        xyz.prepend Indirect
        xyz(prepend Interior)
      end
    ))
    map = Solargraph::SourceMap.map(source)
    pins = map.pins.select{|pin| pin.is_a?(Solargraph::Pin::Reference::Prepend) && pin.namespace == 'Foo'}
    names = pins.map(&:name)
    expect(names).to include('Direct')
    expect(names).not_to include('Indirect')
    expect(names).to include('Interior')
  end

  it "ignores extend calls that are not attached to the current namespace" do
    source = Solargraph::Source.new(%(
      class Foo
        extend Direct
        xyz.extend Indirect
        xyz(extend Interior)
      end
    ))
    map = Solargraph::SourceMap.map(source)
    foo_pin = map.pins.select{|pin| pin.path == 'Foo'}.first
    # expect(foo_pin.extend_references.map(&:name)).to include('Direct')
    # expect(foo_pin.extend_references.map(&:name)).not_to include('Indirect')
    pins = map.pins.select{|pin| pin.is_a?(Solargraph::Pin::Reference::Extend) && pin.namespace == 'Foo'}
    names = pins.map(&:name)
    expect(names).to include('Direct')
    expect(names).not_to include('Indirect')
    expect(names).to include('Interior')
  end

  it "sets scopes for attributes" do
    source = Solargraph::Source.new(%(
      module Foo
        attr_reader :bar1
        class << self
          attr_reader :bar2
        end
      end
    ))
    map = Solargraph::SourceMap.map(source)
    bar1 = map.pins.select{|pin| pin.name == 'bar1'}.first
    expect(bar1.scope).to eq(:instance)
    bar2 = map.pins.select{|pin| pin.name == 'bar2'}.first
    expect(bar2.scope).to eq(:class)
  end

  it "sets attribute visibility" do
    map = Solargraph::SourceMap.load_string(%(
      module Foo
        attr_reader :default_public_method
        private
        attr_reader :private_method
        protected
        attr_reader :protected_method
        public
        attr_reader :explicit_public_method
      end
    ))
    expect(map.first_pin('Foo#default_public_method').visibility).to eq(:public)
    expect(map.first_pin('Foo#private_method').visibility).to eq(:private)
    expect(map.first_pin('Foo#protected_method').visibility).to eq(:protected)
    expect(map.first_pin('Foo#explicit_public_method').visibility).to eq(:public)
  end

  it "processes method directives" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        # @!method bar(baz)
        #   @return [String]
        # @!method bing(bazzle = 'anchor')
        #   @return [String]
        # @!method bravo(charlie = :delta)
        #   @return [String]
        make_bar_attr
        make_bing_attr
        make_bravo_attr
      end
    ))
    pin = map.first_pin('Foo#bar')
    expect(pin.parameter_names).to eq(['baz'])
    expect(pin.return_type.tag).to eq('String')
    pin = map.first_pin('Foo#bing')
    expect(pin.parameter_names).to eq(['bazzle'])
    expect(pin.return_type.tag).to eq('String')
    pin = map.first_pin('Foo#bravo')
    expect(pin.parameter_names).to eq(['charlie'])
    expect(pin.return_type.tag).to eq('String')
  end

  it 'processes singleton method directives' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        # @!method self.bar(baz)
      end
    ))
    pin = map.first_pin('Foo.bar')
    expect(pin.scope).to eq(:class)
  end

  it "processes attribute reader directives" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        # @!attribute [r] bar
        #   @return [String]
        make_bar_attr
      end
    ))
    pin = map.first_pin('Foo#bar')
    expect(pin.return_type.tag).to eq('String')
  end

  it "processes attribute writer directives" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        # @!attribute [w] bar
        #   @return [String]
        make_bar_attr
      end
    ))
    pin = map.first_pin('Foo#bar=')
    expect(pin.return_type.tag).to eq('String')
  end

  it "processes attribute accessor directives" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        # @!attribute [r,w] bar
        #   @return [String]
        make_bar_attr
      end
    ))
    pin = map.first_pin('Foo#bar')
    expect(pin.return_type.tag).to eq('String')
    pin = map.first_pin('Foo#bar=')
    expect(pin.return_type.tag).to eq('String')
  end

  it "processes default attribute directives" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        # @!attribute bar
        #   @return [String]
        make_bar_attr
      end
    ))
    pin = map.first_pin('Foo#bar')
    expect(pin.return_type.tag).to eq('String')
    pin = map.first_pin('Foo#bar=')
    expect(pin.return_type.tag).to eq('String')
  end

  it "processes attribute directives attached to methods" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        # @!attribute [r] bar
        #   @return [String]
        def make_bar_attr
        end
      end
    ))
    pin = map.first_pin('Foo#bar')
    expect(pin.return_type.tag).to eq('String')
  end

  it "processes private visibility directives attached to methods" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        # @!visibility private
        def bar
        end
      end
    ))
    expect(map.first_pin('Foo#bar').visibility).to be(:private)
  end

  it "processes protected visibility directives attached to methods" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        # @!visibility protected
        def bar
        end
      end
    ))
    expect(map.first_pin('Foo#bar').visibility).to be(:protected)
  end

  it "processes public visibility directives attached to methods" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        # @!visibility public
        def bar
        end
      end
    ))
    expect(map.first_pin('Foo#bar').visibility).to be(:public)
  end

  it "does not process attached visibility directives on other methods" do
    map = Solargraph::SourceMap.load_string(%(
      class Example
        # @!visibility private
        def method1; end

        def method2; end
      end
    ))
    method1 = map.first_pin('Example#method1')
    expect(method1.visibility).to be(:private)
    method2 = map.first_pin('Example#method2')
    expect(method2.visibility).to be(:public)
  end

  it "processes class-wide private visibility directives" do
    map = Solargraph::SourceMap.load_string(%(
      class Example
        # @!visibility private

        def method1; end

        def method2; end

        # @!visibility public
        def method3; end
      end
    ))
    method1 = map.first_pin('Example#method1')
    expect(method1.visibility).to be(:private)
    method2 = map.first_pin('Example#method2')
    expect(method2.visibility).to be(:private)
    method3 = map.first_pin('Example#method3')
    expect(method3.visibility).to be(:public)
  end

  it "processes attribute directives at class endings" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        # @!attribute [r] bar
        #   @return [String]
      end
    ))
    pin = map.first_pin('Foo#bar')
    expect(pin.return_type.tag).to eq('String')
  end

  it "finds assignment nodes for local variables using nil guards" do
    map = Solargraph::SourceMap.load_string(%(
      x ||= []
    ))
    pin = map.locals.first
    # @todo Dirty test
    expect([:ZLIST, :ZARRAY, :array]).to include(pin.assignment.type)
  end

  it "finds assignment nodes for instance variables using nil guards" do
    map = Solargraph::SourceMap.load_string(%(
      @x ||= []
    ))
    pin = map.pins.last
    # @todo Dirty test
    expect([:ZLIST, :ZARRAY, :array]).to include(pin.assignment.type)
  end

  it "finds assignment nodes for class variables using nil guards" do
    map = Solargraph::SourceMap.load_string(%(
      @@x ||= []
    ))
    pin = map.pins.last
    # @todo Dirty test
    expect([:ZLIST, :ZARRAY, :array]).to include(pin.assignment.type)
  end

  it "finds assignment nodes for global variables using nil guards" do
    map = Solargraph::SourceMap.load_string(%(
      $x ||= []
    ))
    pin = map.pins.last
    # @todo Dirty test
    expect([:ZLIST, :ZARRAY, :array]).to include(pin.assignment.type)
  end

  it "requalifies namespace definitions with leading colons" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        class ::Bar; end
      end
    ))
    expect(map.pins.map(&:path)).to include('Foo')
    expect(map.pins.map(&:path)).to include('Bar')
    expect(map.pins.map(&:path)).not_to include('Foo::Bar')
  end

  it "maps method parameters" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar baz, boo = 'boo', key: 'value'
        end
      end
    ))
    pin = map.first_pin('Foo#bar')
    expect(pin.parameter_names).to eq(['baz', 'boo', 'key'])
    pin = map.locals.select{|p| p.name == 'baz'}.first
    expect(pin).to be_a(Solargraph::Pin::Parameter)
    pin = map.locals.select{|p| p.name == 'boo'}.first
    expect(pin).to be_a(Solargraph::Pin::Parameter)
    pin = map.locals.select{|p| p.name == 'key'}.first
    expect(pin).to be_a(Solargraph::Pin::Parameter)
  end

  it "maps method splat parameters" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar *baz
        end
      end
    ))
    pin = map.first_pin('Foo#bar')
    expect(pin.parameters.length).to eq(1)
    expect(pin.parameters.first.name).to eq('baz')
  end

  it "maps method block parameters" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar &block
        end
      end
    ))
    pin = map.first_pin('Foo#bar')
    expect(pin.parameters.length).to eq(1)
    expect(pin.parameters.first.name).to eq('block')
  end

  it "adds superclasses to class pins" do
    map = Solargraph::SourceMap.load_string(%(
      class Sub < Sup; end
    ))
    # pin = map.first_pin('Sub')
    # expect(pin.superclass_reference.name).to eq('Sup')
    pin = map.pins.select{|p| p.is_a?(Solargraph::Pin::Reference::Superclass)}.first
    expect(pin.namespace).to eq('Sub')
    expect(pin.name).to eq('Sup')
  end

  it "modifies scope and visibility for module functions" do
    map = Solargraph::SourceMap.load_string(%(
      module Functions
        module_function
        def foo; end
      end
    ))
    pin = map.first_pin('Functions.foo')
    expect(pin.visibility).to eq(:public)
    pin = map.first_pin('Functions#foo')
    expect(pin.visibility).to eq(:private)
  end

  it "recognizes single module functions" do
    map = Solargraph::SourceMap.load_string(%(
      module Functions
        module_function def foo; end
        def bar; end
      end
    ))
    pin = map.first_pin('Functions.foo')
    expect(pin.visibility).to eq(:public)
    pin = map.first_pin('Functions#foo')
    expect(pin.visibility).to eq(:private)
    pin = map.first_pin('Functions#bar')
    expect(pin.visibility).to eq(:public)
  end

  it "remaps methods for module_function symbol arguments" do
    map = Solargraph::SourceMap.load_string(%(
      module Functions
        def foo
          @foo = 'foo'
        end
        def bar
          @bar = 'bar'
        end
        module_function :foo
      end
    ))
    pin = map.first_pin('Functions.foo')
    expect(pin.visibility).to eq(:public)
    pin = map.first_pin('Functions#foo')
    expect(pin.visibility).to eq(:private)
    pin = map.first_pin('Functions#bar')
    expect(pin.visibility).to eq(:public)
    pin = map.pins.select{|p| p.name == '@foo' and p.context.scope == :class}.first
    expect(pin).to be_a(Solargraph::Pin::InstanceVariable)
    pin = map.pins.select{|p| p.name == '@foo' and p.context.scope == :instance}.first
    expect(pin).to be_a(Solargraph::Pin::InstanceVariable)
  end

  it "modifies instance variables in module functions" do
    map = Solargraph::SourceMap.load_string(%(
      module Functions
        module_function
        def foo
          @foo = 'foo'
          @bar ||= 'bar'
        end
      end
    ))
    pin = map.pins.select{|p| p.name == '@foo' and p.context.scope == :class}.first
    expect(pin).to be_a(Solargraph::Pin::InstanceVariable)
    pin = map.pins.select{|p| p.name == '@foo' and p.context.scope == :instance}.first
    expect(pin).to be_a(Solargraph::Pin::InstanceVariable)
    pin = map.pins.select{|p| p.name == '@bar' and p.context.scope == :class}.first
    expect(pin).to be_a(Solargraph::Pin::InstanceVariable)
    pin = map.pins.select{|p| p.name == '@bar' and p.context.scope == :instance}.first
    expect(pin).to be_a(Solargraph::Pin::InstanceVariable)
  end

  it "maps class variables" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        @@bar = 'bar'
        @@baz ||= 'baz'
      end
    ))
    pin = map.pins.select{|p| p.name == '@@bar'}.first
    expect(pin).to be_a(Solargraph::Pin::ClassVariable)
    pin = map.pins.select{|p| p.name == '@@baz'}.first
    expect(pin).to be_a(Solargraph::Pin::ClassVariable)
  end

  it "maps local variables" do
    map = Solargraph::SourceMap.load_string(%(
      x = y
    ))
    pin = map.locals.select{|p| p.name == 'x'}.first
    expect(pin).to be_a(Solargraph::Pin::LocalVariable)
  end

  it "maps global variables" do
    map = Solargraph::SourceMap.load_string(%(
      $x = y
    ))
    pin = map.pins.select{|p| p.name == '$x'}.first
    expect(pin).to be_a(Solargraph::Pin::GlobalVariable)
  end

  it "maps constants" do
    map = Solargraph::SourceMap.load_string(%(
      module Foo
        BAR = 'bar'
      end
    ))
    pin = map.first_pin('Foo::BAR')
    expect(pin).to be_a(Solargraph::Pin::Constant)
  end

  it "maps singleton methods" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        def self.bar; end
      end
    ))
    pin = map.first_pin('Foo.bar')
    expect(pin).to be_a(Solargraph::Pin::Method)
    expect(pin.context.scope).to be(:class)
  end

  it "maps requalified singleton methods" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo; end
      class Bar
        def Bar.baz; end
        def Foo.boo; end
        def boo; end
      end
    ))
    pin = map.first_pin('Bar.baz')
    expect(pin).to be_a(Solargraph::Pin::Method)
    expect(pin.context.scope).to be(:class)
    pin = map.first_pin('Foo.boo')
    expect(pin).to be_a(Solargraph::Pin::Method)
    expect(pin.context.scope).to be(:class)
    pin = map.first_pin('Bar#boo')
    expect(pin).to be_a(Solargraph::Pin::Method)
    expect(pin.context.scope).to be(:instance)
  end

  it "maps private class methods" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        def self.bar; end
        private_class_method :bar
      end
    ))
    pin = map.first_pin('Foo.bar')
    expect(pin).to be_a(Solargraph::Pin::Method)
    expect(pin.visibility).to be(:private)
  end

  it "maps singly defined private class methods" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        private_class_method def bar; end
      end
    ))
    pin = map.first_pin('Foo.bar')
    expect(pin).to be_a(Solargraph::Pin::Method)
    expect(pin.visibility).to be(:private)
  end

  it "maps private constants" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        BAR = 'bar'
        private_constant :BAR
      end
    ))
    pin = map.first_pin('Foo::BAR')
    expect(pin).to be_a(Solargraph::Pin::Constant)
    expect(pin.visibility).to be(:private)
  end

  it "maps private namespaces" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        class Bar; end
        private_constant :Bar
      end
    ))
    pin = map.first_pin('Foo::Bar')
    expect(pin).to be_a(Solargraph::Pin::Namespace)
    expect(pin.visibility).to be(:private)
  end

  it "maps attribute writers" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        attr_writer :bar
      end
    ))
    expect(map.pins.map(&:path)).to include('Foo#bar=')
    expect(map.pins.map(&:path)).not_to include('Foo#bar')
  end

  it "maps attribute accessors" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        attr_accessor :bar
      end
    ))
    expect(map.pins.map(&:path)).to include('Foo#bar=')
    expect(map.pins.map(&:path)).to include('Foo#bar')
  end

  it "maps extend self" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        extend self
        def bar; end
      end
    ))
    pin = map.first_pin('Foo')
    # expect(pin.extend_references.map(&:name)).to include('Foo')
    pin = map.pins.select{|p| p.is_a?(Solargraph::Pin::Reference::Extend)}.first
    expect(pin.namespace).to eq('Foo')
    expect(pin.name).to eq('Foo')
  end

  it "maps require calls" do
    map = Solargraph::SourceMap.load_string(%(
      require 'set'
    ))
    pin = map.pins.select{|p| p.is_a?(Solargraph::Pin::Reference::Require)}.first
    expect(pin.name).to eq('set')
  end

  it "ignores dynamic require calls" do
    map = Solargraph::SourceMap.load_string(%(
      path = 'solargraph'
      require path
    ))
    expect(map.requires.length).to eq(0)
  end

  it "maps block parameters" do
    map = Solargraph::SourceMap.load_string(%(
      x.each do |y|
      end
    ))
    pin = map.locals.select{|p| p.name == 'y'}.first
    expect(pin).to be_a(Solargraph::Pin::Parameter)
  end

  it "forces initialize methods to be private" do
    map = Solargraph::SourceMap.load_string('
      class Foo
        def initialize name
        end
      end
    ')
    pin = map.first_pin('Foo#initialize')
    expect(pin.visibility).to be(:private)
  end

  it "creates Class.new methods for Class#initialize" do
    map = Solargraph::SourceMap.load_string('
      class Foo
        def initialize name
        end
      end
    ')
    pin = map.first_pin('Foo.new')
    expect(pin).to be_a(Solargraph::Pin::Method)
    expect(pin.return_type.tag).to eq('self')
  end

  it "maps top-level methods" do
    map = Solargraph::SourceMap.load_string(%(
      def foo(bar, baz)
      end
    ))
    # @todo Are these paths okay?
    pin = map.first_pin('#foo')
    expect(pin).to be_a(Solargraph::Pin::Method)
  end

  it "maps root blocks to class scope" do
    smap = Solargraph::SourceMap.load_string(%(
      @a = some_array
      @a.each do |b|
        b
      end
    ), 'test.rb')
    pin = smap.pins.select{|p| p.is_a?(Solargraph::Pin::Block)}.first
    expect(pin.context.scope).to eq(:class)
  end

  it "maps class method blocks to class scope" do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo
        def self.bar
          @a = some_array
          @a.each do |b|
            b
          end
        end
      end
    ))
    pin = smap.pins.select{|p| p.is_a?(Solargraph::Pin::Block)}.first
    expect(pin.context.scope).to eq(:class)
  end

  it "maps instance method blocks to instance scope" do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar
          @a = some_array
          @a.each do |b|
            b
          end
        end
      end
    ))
    pin = smap.pins.select{|p| p.is_a?(Solargraph::Pin::Block)}.first
    expect(pin.context.scope).to eq(:instance)
  end

  it "maps rebased namespaces without leading colons" do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo
        class ::Bar
          def baz; end
        end
      end
    ))
    expect(smap.first_pin('Foo::Bar')).to be_nil
    expect(smap.first_pin('Bar')).to be_a(Solargraph::Pin::Namespace)
    expect(smap.first_pin('Bar#baz')).to be_a(Solargraph::Pin::Method)
  end

  it "maps contexts of constants" do
    var = 'BAR'
    smap = Solargraph::SourceMap.load_string("#{var} = nil")
    pin = smap.pins.select{|p| p.name == var}.first
    expect(pin.context).to be_a(Solargraph::ComplexType)
    smap = Solargraph::SourceMap.load_string("#{var} ||= nil")
    pin = smap.pins.select{|p| p.name == var}.first
    expect(pin.context).to be_a(Solargraph::ComplexType)
  end

  it "maps contexts of instance variables" do
    var = '@bar'
    smap = Solargraph::SourceMap.load_string("#{var} = nil")
    pin = smap.pins.select{|p| p.name == var}.first
    expect(pin.context).to be_a(Solargraph::ComplexType)
    smap = Solargraph::SourceMap.load_string("#{var} ||= nil")
    pin = smap.pins.select{|p| p.name == var}.first
    expect(pin.context).to be_a(Solargraph::ComplexType)
  end

  it "maps contexts of class variables" do
    var = '@@bar'
    smap = Solargraph::SourceMap.load_string("#{var} = nil")
    pin = smap.pins.select{|p| p.name == var}.first
    expect(pin.context).to be_a(Solargraph::ComplexType)
    smap = Solargraph::SourceMap.load_string("#{var} ||= nil")
    pin = smap.pins.select{|p| p.name == var}.first
    expect(pin.context).to be_a(Solargraph::ComplexType)
  end

  it "maps contexts of global variables" do
    var = '$bar'
    smap = Solargraph::SourceMap.load_string("#{var} = nil")
    pin = smap.pins.select{|p| p.name == var}.first
    expect(pin.context).to be_a(Solargraph::ComplexType)
    smap = Solargraph::SourceMap.load_string("#{var} ||= nil")
    pin = smap.pins.select{|p| p.name == var}.first
    expect(pin.context).to be_a(Solargraph::ComplexType)
  end

  it "maps contexts of local variables" do
    var = 'bar'
    smap = Solargraph::SourceMap.load_string("#{var} = nil")
    pin = smap.locals.select{|p| p.name == var}.first
    expect(pin.context).to be_a(Solargraph::ComplexType)
    smap = Solargraph::SourceMap.load_string("#{var} ||= nil")
    pin = smap.locals.select{|p| p.name == var}.first
    expect(pin.context).to be_a(Solargraph::ComplexType)
  end

  it "maps method aliases" do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar; end
        alias baz bar
      end
    ))
    pin = smap.pins.select{|p| p.path == 'Foo#baz'}.first
    expect(pin).to be_a(Solargraph::Pin::MethodAlias)
  end

  it "maps attribute aliases" do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo
        attr_accessor :bar
        alias baz bar
      end
    ))
    pin = smap.pins.select{|p| p.path == 'Foo#baz'}.first
    expect(pin).to be_a(Solargraph::Pin::MethodAlias)
  end

  it "maps class method aliases" do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo
        class << self
          def bar; end
          alias baz bar
        end
      end
    ))
    pin = smap.pins.select{|p| p.path == 'Foo.baz'}.first
    expect(pin).to be_a(Solargraph::Pin::MethodAlias)
    expect(pin.location.range.start.line).to eq(4)
  end

  it "maps method macros" do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo
        # @!macro
        #   @return [$1]
        def make klass; end
      end
    ), 'test.rb')
    pin = smap.pins.select{|p| p.path == 'Foo#make'}.first
    expect(pin.macros).not_to be_empty
  end

  it "maps method directives" do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo
        # @!method bar(baz)
        #   @return [String]
      end
    ), 'test.rb')
    pin = smap.pins.select{|p| p.path == 'Foo#bar'}.first
    expect(pin.return_type.tag).to eq('String')
    expect(pin.location.filename).to eq('test.rb')
  end

  it "maps aliases from alias_method" do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo
        class << self
          def bar; end
          alias_method :baz, :bar
        end
      end
    ))
    pin = smap.pins.select{|p| p.path == 'Foo.baz'}.first
    expect(pin).to be_a(Solargraph::Pin::MethodAlias)
    expect(pin.location.range.start.line).to eq(4)
  end

  it "maps aliases with unknown bases" do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo
        alias bar baz
      end
    ))
    pin = smap.pins.select{|p| p.path == 'Foo#bar'}.first
    expect(pin).to be_a(Solargraph::Pin::MethodAlias)
  end

  it "maps aliases to superclass methods" do
    smap = Solargraph::SourceMap.load_string(%(
      class Sup
        # My foo method
        def foo; end
      end
      class Sub < Sup
        alias bar foo
      end
    ))
    pin = smap.pins.select{|p| p.path == 'Sub#bar'}.first
    expect(pin).to be_a(Solargraph::Pin::MethodAlias)
  end

  it "uses nodes for method parameter assignments" do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar(baz = quz)
        end
      end
    ))
    pin = smap.locals.select{|p| p.name == 'baz'}.first
    # expect(pin.assignment).to be_a(Parser::AST::Node)
    expect(Solargraph::Parser.is_ast_node?(pin.assignment)).to be(true)
  end

  it "defers resolution of distant alias_method aliases" do
    smap = Solargraph::SourceMap.load_string(%(
      class MyClass
        alias_method :foo, :bar
      end
    ))
    pin = smap.pins.select{|p| p.is_a?(Solargraph::Pin::MethodAlias)}.first
    expect(pin).not_to be_nil
  end

  it "maps explicit begin nodes" do
    smap = Solargraph::SourceMap.load_string(%(
      def foo
        begin
          @x = make_x
        end
      end
    ))
    pin = smap.pins.select{|p| p.name == '@x'}.first
    expect(pin).not_to be_nil
  end

  it "maps rescue nodes" do
    smap = Solargraph::SourceMap.load_string(%(
      def foo
        @x = make_x
      rescue => err
        @y = y
      end
    ))
    err_pin = smap.locals{|p| p.name == 'err'}.first
    expect(err_pin).not_to be_nil
    var_pin = smap.pins.select{|p| p.name == '@y'}.first
    expect(var_pin).not_to be_nil
  end

  it "maps begin/rescue nodes" do
    smap = Solargraph::SourceMap.load_string(%(
      def foo
        begin
          @x = make_x
        rescue => err
          @y = y
        end
      end
    ))
    err_pin = smap.locals{|p| p.name == 'err'}.first
    expect(err_pin).not_to be_nil
    var_pin = smap.pins.select{|p| p.name == '@y'}.first
    expect(var_pin).not_to be_nil
  end

  it "maps classes with long namespaces" do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo::Bar
      end
    ), 'test.rb')
    pin = smap.pins.select{|p| p.path == 'Foo::Bar'}.first
    expect(pin).not_to be_nil
    expect(pin.namespace).to eq('Foo')
    expect(pin.name).to eq('Bar')
    expect(pin.path).to eq('Foo::Bar')
  end

  it "ignores aliases that do not map to methods or attributes" do
    expect {
      smap = Solargraph::SourceMap.load_string(%(
        class Foo
          xyz = String
          alias foo xyz
          alias_method :foo, :xyz
        end
      ), 'test.rb')
    }.not_to raise_error
  end

  it "ignores private_class_methods that do not map to methods or attributes" do
    expect {
      smap = Solargraph::SourceMap.load_string(%(
        class Foo
          var = some_method
          private_class_method :var
        end
      ), 'test.rb')
    }.not_to raise_error
  end

  it "ignores private_constants that do not map to namespaces or constants" do
    expect {
      smap = Solargraph::SourceMap.load_string(%(
        class Foo
          var = some_method
          private_constant :var
        end
      ), 'test.rb')
    }.not_to raise_error
  end

  it "ignores module_functions that do not map to methods or attributes" do
    expect {
      smap = Solargraph::SourceMap.load_string(%(
        class Foo
          var = some_method
          module_function :var
        end
      ), 'test.rb')
    }.not_to raise_error
  end

  it "handles parse directives" do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo
        # @!parse
        #   class Bar; end
      end
    ))
    expect(smap.pins.map(&:path)).to include('Foo::Bar')
  end

  it "ignores syntax errors in parse directives" do
    expect {
      Solargraph::SourceMap.load_string(%(
        class Foo
          # @!parse
          #   def
        end
      ))
      }.not_to raise_error
  end

  it "sets visibility for symbol parameters" do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo
        def pub; end
        def bar; end
        private :bar
        def baz; end
        def pro; end
        protected 'pro'
      end
    ))
    pub = smap.pins.select{|pin| pin.path == 'Foo#pub'}.first
    expect(pub.visibility).to eq(:public)
    bar = smap.pins.select{|pin| pin.path == 'Foo#bar'}.first
    expect(bar.visibility).to eq(:private)
    baz = smap.pins.select{|pin| pin.path == 'Foo#baz'}.first
    expect(baz.visibility).to eq(:public)
    pro = smap.pins.select{|pin| pin.path == 'Foo#pro'}.first
    expect(pro.visibility).to eq(:protected)
  end

  it "ignores errors in method directives" do
    expect {
      Solargraph::SourceMap.load_string(%[
        class Foo
          # @!method bar(
        end
      ])
    }.not_to raise_error
  end

  it "handles invalid byte sequences" do
    expect {
      Solargraph::SourceMap.load(File.join('spec', 'fixtures', 'invalid_utf8.rb'))
    }.not_to raise_error
  end

  it "applies private_class_method to attributes" do
    smap = Solargraph::SourceMap.load_string(%(
      module Foo
        class << self
          attr_reader :bar
        end
        private_class_method :bar
      end
    ))
    pin = smap.pins.select{|pin| pin.path == 'Foo.bar'}.first
    expect(pin.visibility).to eq(:private)
  end

  it 'maps rest arguments' do
    smap = Solargraph::SourceMap.load_string(%(
      module Foo
        def bar(*baz); end
      end
    ))
    local = smap.locals.first
    expect(local.name).to eq('baz')
    pin = smap.first_pin('Foo#bar')
    expect(pin.parameters.length).to eq(1)
    expect(pin.parameters.first.name).to eq('baz')
  end

  it 'maps optional arguments' do
    smap = Solargraph::SourceMap.load_string(%(
      module Foo
        def bar(baz=nil); end
      end
    ))
    local = smap.locals.first
    expect(local.name).to eq('baz')
    pin = smap.first_pin('Foo#bar')
    expect(pin.parameters.length).to eq(1)
    expect(pin.parameters.first.name).to eq('baz')
  end

  it 'maps keyword arguments' do
    smap = Solargraph::SourceMap.load_string(%(
      module Foo
        def bar(baz:); end
      end
    ))
    local = smap.locals.first
    expect(local.name).to eq('baz')
    pin = smap.first_pin('Foo#bar')
    expect(pin.parameters.length).to eq(1)
    expect(pin.parameters.first.name).to eq('baz')
  end

  it 'maps optional keyword arguments' do
    smap = Solargraph::SourceMap.load_string(%(
      module Foo
        def bar(baz:nil); end
      end
    ))
    local = smap.locals.first
    expect(local.name).to eq('baz')
    pin = smap.first_pin('Foo#bar')
    expect(pin.parameters.length).to eq(1)
    expect(pin.parameters.first.name).to eq('baz')
  end

  it 'maps block arguments' do
    smap = Solargraph::SourceMap.load_string(%(
      module Foo
        def bar(&block); end
      end
    ))
    local = smap.locals.first
    expect(local.name).to eq('block')
    pin = smap.first_pin('Foo#bar')
    expect(pin.parameters.length).to eq(1)
    expect(pin.parameters.first.name).to eq('block')
  end

  it 'maps method directives to singleton classes' do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo
        class << self
          # @!method bar()
        end
      end
    ))
    paths = smap.pins.map(&:path)
    expect(paths).to include('Foo.bar')
    expect(paths).not_to include('Foo#bar')
  end

  it 'maps parse directives to singleton classes' do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo
        class << self
          # @!parse def bar; end
        end
      end
    ))
    paths = smap.pins.map(&:path)
    expect(paths).to include('Foo.bar')
    expect(paths).not_to include('Foo#bar')
  end

  it 'maps attribute directives to singleton classes' do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo
        class << self
          # @!attribute bar
        end
      end
    ))
    paths = smap.pins.map(&:path)
    expect(paths).to include('Foo.bar')
    expect(paths).not_to include('Foo#bar')
  end

  it 'sets return types for exception variables' do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar
          xyz
        rescue ArgumentError => e
          e._
        end
      end
    ), 'test.rb')
    pin = smap.locals.first
    expect(pin.return_type.tag).to eq('ArgumentError')
  end

  it 'handles rescue nodes without exception variables' do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar
          xyz
        rescue ArgumentError
          # do nothing
        end
      end
    ), 'test.rb')
    expect(smap.locals).to be_empty
  end

  it 'processes comments without associations' do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo; end
      # @!parse
      #   class Foo
      #     def bar; end
      #   end
    ))
    expect(smap.first_pin('Foo#bar')).to be_a(Solargraph::Pin::Method)
  end

  it 'ignores attribute directives without names' do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo
        # @!attribute
      end
    ))
    attrs = smap.pins.select { |pin| pin.is_a?(Solargraph::Pin::Method) && pin.attribute? }
    expect(attrs).to be_empty
  end

  it 'ignores method directives without names' do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo
        # @!method
      end
    ))
    attrs = smap.pins.select { |pin| pin.is_a?(Solargraph::Pin::Method) }
    expect(attrs).to be_empty
  end

  it 'maps multiple method directives in a class' do
    source = Solargraph::Source.load_string(%(
      class Foo
        class << self
          # @!method bar
          # @!method baz
        end
      end  
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    bar = api_map.get_path_pins('Foo.bar').first
    expect(bar).to be_a(Solargraph::Pin::Base)
    baz = api_map.get_path_pins('Foo.baz').first
    expect(baz).to be_a(Solargraph::Pin::Base)
  end

  it 'maps method directives in class headers' do
    source = Solargraph::Source.load_string(%(
      # @!method self.bar
      class Foo
        class << self
          # @!method baz
        end
      end  
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    bar = api_map.get_path_pins('Foo.bar').first
    expect(bar).to be_a(Solargraph::Pin::Base)
    baz = api_map.get_path_pins('Foo.baz').first
    expect(baz).to be_a(Solargraph::Pin::Base)
  end

  it 'processes override directives' do
    source = Solargraph::Source.load_string(%(
      class Foo
        def bar; end
      end
      # @!override Foo#bar
      #   return [String]
    ), 'test.rb')
    pins, _locals = Solargraph::SourceMap::Mapper.map(source)
    over = pins.select { |pin| pin.is_a?(Solargraph::Pin::Reference::Override) }.first
    expect(over.name).to eq('Foo#bar')
  end

  it 'maps kwrestarg parameters' do
    source = Solargraph::Source.load_string(%(
      class Foo
        def bar(**baz); end
      end
    ))
    _pins, locals = Solargraph::SourceMap::Mapper.map(source)
    param = locals.select { |pin| pin.is_a?(Solargraph::Pin::Parameter) }.first
    expect(param).to be_kwrestarg
  end

  it 'maps hash parameters as kwrestargs' do
    source = Solargraph::Source.load_string(%(
      class Foo
        def bar(baz = {}); end
      end
    ))
    _pins, locals = Solargraph::SourceMap::Mapper.map(source)
    param = locals.select { |pin| pin.is_a?(Solargraph::Pin::Parameter) }.first
    expect(param).to be_kwrestarg
  end

  it 'maps local variables in blocks' do
    source = Solargraph::Source.load_string(%(
      1.times do
        var = 'var'
      end
    ))
    _pins, locals = Solargraph::SourceMap::Mapper.map(source)
    expect(locals).to be_one
  end

  it 'handles mapped methods without arguments' do
    source = Solargraph::Source.load_string(%(
      class Foo
        # The Mapper expects to generate pins from these method calls. It
        # should gracefully ignore them if they don't have arguments.
        include
        extend
        require
        attr_reader
        attr_writer
        attr_accessor
        autoload
        alias
        alias_method
      end
    ))
    pins, locals = Solargraph::SourceMap::Mapper.map(source)
    expect(pins).to be_one
    expect(locals).to be_empty
  end

  it 'maps local variables from for constructs' do
    map = Solargraph::SourceMap.load_string(%(
      for x in y
        use x
      end
    ))
    expect(map.locals.first.name).to eq('x')
  end

  it 'marks explicit methods' do
    map = Solargraph::SourceMap.load_string(%(
      def foo(bar); end
    ))
    expect(map.first_pin('#foo')).to be_explicit
  end

  it 'marks non-explicit methods' do
    # HACK: The directive doesn't work if it's not attached to code
    map = Solargraph::SourceMap.load_string(%(
      # @!method foo(bar)
      nil
    ))
    expect(map.first_pin('#foo')).not_to be_explicit
  end

  it 'marks pins from @!parse directives as explicit' do
    # @note Although it seems reasonable that a method pin from a @!parse
    #   directive would not be explicit, we're following YARD's lead and
    #   marking them explicit instead.
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        # @!parse
        #   def bar; end
      end
    ))
    bar = map.first_pin('Foo#bar')
    expect(bar).to be_explicit
  end

  it 'maps parameters to updated module_function methods' do
    map = Solargraph::SourceMap.load_string(%(
      module Foo
        def bar(baz)
        end

        module_function :bar
      end
    ))

    cpin = map.first_pin('Foo.bar')
    expect(cpin.parameters).to be_one
    expect(cpin.parameters.first.name).to eq('baz')

    ipin = map.first_pin('Foo#bar')
    expect(ipin.parameters).to be_one
    expect(ipin.parameters.first.name).to eq('baz')
  end

  it 'handles private_class_method without arguments' do
    code = %(
      class Foo
        private_class_method
      end
    )
    expect {
      Solargraph::SourceMap.load_string(code, 'test.rb')
    }.not_to raise_error
  end

  it 'positions method directive pins' do
    map = Solargraph::SourceMap.load_string(%(
      # @!method foo
      # @!method bar
    ))
    foo = map.first_pin('#foo')
    expect(foo.location.range.start.line).to eq(1)
    bar = map.first_pin('#bar')
    expect(bar.location.range.start.line).to eq(2)
  end

  it 'maps function calls to visibility methods' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        private()
        def meth; end
      end

      class Bar
        def meth; end
        private(:meth)
      end
    ))
    foo_meth = map.first_pin('Foo#meth')
    expect(foo_meth.visibility).to eq(:private)
    bar_meth = map.first_pin('Bar#meth')
    expect(bar_meth.visibility).to eq(:private)
  end

  it 'maps Bundler.require to require "bundler/require"' do
    map = Solargraph::SourceMap.load_string(%(
      Bundler.require
    ))
    pin = map.pins.select { |pin| pin.is_a?(Solargraph::Pin::Reference::Require) }.first
    expect(pin.name).to eq('bundler/require')
  end

  it 'correctly orders optargs and blockargs' do
    map = Solargraph::SourceMap.load_string(%(
      def foo bar = nil, &block
      end
    ))
    pin = map.first_pin('#foo')
    expect(pin.parameters.last.full).to eq('&block')
  end

  it 'correctly orders kwargs and blockargs' do
    map = Solargraph::SourceMap.load_string(%(
      def foo bar:, &block
      end
    ))
    pin = map.first_pin('#foo')
    expect(pin.parameters.last.full).to eq('&block')
  end

  it 'correctly orders kwargs and double splats' do
    map = Solargraph::SourceMap.load_string(%(
      def foo bar:, **splat
      end
    ))
    pin = map.first_pin('#foo')
    expect(pin.parameters.last.full).to eq('**splat')
  end

  it 'gracefully handles misunderstood macros' do
    expect {
      Solargraph::SourceMap.load_string(%(
        module Foo
          # @!macro macro1
          #   @!macro macro2
          #   @!method macro_method

          # @!macro macro1
          class Bar; end
        end
      ))
    }.not_to raise_error
  end

  it 'maps autoload paths' do
    map = Solargraph::SourceMap.load_string(%(
      autoload :Foo, 'path/to/foo'
    ))
    expect(map.requires.map(&:name)).to eq(['path/to/foo'])
  end

  it 'maps @!method parameters' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        # @!method bar(baz: 'buzz')
      end
    ))
    pin = map.first_pin('Foo#bar')
    expect(pin.parameters.first.full).to eq("baz: 'buzz'")
  end

  it 'locates @!method macros' do
    map = Solargraph::SourceMap.load_string(%(
      # Foo description
      # @!method bar
      class Foo; end
    ))
    pin = map.first_pin('Foo#bar')
    expect(pin.location.range.start.line).to eq(2)
  end

  it 'locates pins in @!parse macros' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        # @!parse
        #   def bar; end
      end
    ))
    pin = map.first_pin('Foo#bar')
    expect(pin.location.range.start.line).to eq(3)
  end

  it 'handles bare parse directives with comments' do
    map = Solargraph::SourceMap.load_string(%(
      # This file is nothing but a parse
      # with some comments above it
      # @!parse
      #   class Foo
      #     def bar; end
      #   end))
    pin = map.first_pin('Foo#bar')
    expect(pin.location.range.start.line).to eq(5)
  end

  it 'flags method pins as explicit' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar; end
      end
    ))
    bar = map.first_pin('Foo#bar')
    expect(bar).to be_explicit
  end

  it 'separates parameters from local variables' do
    map = Solargraph::SourceMap.load_string(%(
      def foo(bar)
        for i in (bar.length - 1).downto(0) do
          puts bar[i]
        end
      end
    ))
    pin = map.first_pin('#foo')
    expect(pin.parameters.length).to eq(1)
  end

  it 'maps visibility calls with method arguments' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar; end
        private def baz; end
        def quz; end
      end
    ))
    expect(map.first_pin('Foo#bar').visibility).to be(:public)
    expect(map.first_pin('Foo#baz').visibility).to be(:private)
    expect(map.first_pin('Foo#quz').visibility).to be(:public)
  end

  it 'encloses class_eval calls in receivers' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
      end

      class Bar
        Foo.class_eval do
          def foobaz; end
        end

        class_eval do
          def barbaz; end
        end
      end
    ))
    paths = map.pins.map(&:path)
    expect(paths).to include('Foo#foobaz')
    expect(paths).to include('Bar#barbaz')
  end

  it 'sends local variables to remote class_eval receivers' do
    map = Solargraph::SourceMap.load_string(%(
      class Bar; end
      class Foo
        lvar = 'lvar'
        Bar.class_eval do
          def barbaz; end
        end
      end
    ), 'test.rb')
    locals = map.locals_at(
      Solargraph::Location.new(
        'test.rb',
        Solargraph::Range.from_to(5, 0, 5, 0)
      )
    ).map(&:name)
    expect(locals).to eq(['lvar'])
  end

  it 'handles invalid byte sequences' do
    expect {
      Solargraph::SourceMap.load('spec/fixtures/invalid_byte.rb')
    }.not_to raise_error
  end

  it 'handles invalid byte sequences in stringified node comments' do
    expect {
      Solargraph::SourceMap.load('spec/fixtures/invalid_node_comment.rb')
    }.not_to raise_error
  end

  it 'parses method directives that start with multiple hashes' do
    source = %(
      module Bar
        ##
        # @!method foobar()
        #   @return [String]
        define_method :foobar do
          "foobar"
        end
      end
    )
    map = Solargraph::SourceMap.load_string(source)
    pin = map.first_pin('Bar#foobar')
    expect(pin.path).to eq('Bar#foobar')
  end
end
