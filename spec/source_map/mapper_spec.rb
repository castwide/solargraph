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
    expect(foo_pin.return_type.tag).to eq('Foo')
    bar_pin = map.pins.select{|pin| pin.path == 'Foo::Bar.new'}.first
    expect(bar_pin.return_type.tag).to eq('Foo::Bar')
  end

  it "ignores include calls that are not attached to the current namespace" do
    # @todo The include call inside of xyz args is probably valid
    source = Solargraph::Source.new(%(
      class Foo
        include Direct
        xyz.include Indirect
        # xyz(include Indirect)
      end
    ))
    map = Solargraph::SourceMap.map(source)
    pins = map.pins.select{|pin| pin.is_a?(Solargraph::Pin::Reference::Include) && pin.namespace == 'Foo'}
    names = pins.map(&:name)
    expect(names).to include('Direct')
    expect(names).not_to include('Indirect')
  end

  it "ignores extend calls that are not attached to the current namespace" do
    # @todo The include call inside of xyz args is probably valid
    source = Solargraph::Source.new(%(
      class Foo
        extend Direct
        xyz.extend Indirect
        # xyz(extend Indirect)
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
        make_bar_attr
      end
    ))
    pin = map.first_pin('Foo#bar')
    expect(pin.parameter_names).to eq(['baz'])
    expect(pin.return_type.tag).to eq('String')
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
    expect(pin.assignment.to_s).to eq('(array)')
  end

  it "finds assignment nodes for instance variables using nil guards" do
    map = Solargraph::SourceMap.load_string(%(
      @x ||= []
    ))
    pin = map.pins.last
    expect(pin.assignment.to_s).to eq('(array)')
  end

  it "finds assignment nodes for class variables using nil guards" do
    map = Solargraph::SourceMap.load_string(%(
      @@x ||= []
    ))
    pin = map.pins.last
    expect(pin.assignment.to_s).to eq('(array)')
  end

  it "finds assignment nodes for global variables using nil guards" do
    map = Solargraph::SourceMap.load_string(%(
      $x ||= []
    ))
    pin = map.pins.last
    expect(pin.assignment.to_s).to eq('(array)')
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
    expect(pin.parameters).to eq(['baz', "boo = 'boo'", "key: 'value'"])
    pin = map.locals.select{|p| p.name == 'baz'}.first
    expect(pin).to be_a(Solargraph::Pin::MethodParameter)
    pin = map.locals.select{|p| p.name == 'boo'}.first
    expect(pin).to be_a(Solargraph::Pin::MethodParameter)
    pin = map.locals.select{|p| p.name == 'key'}.first
    expect(pin).to be_a(Solargraph::Pin::MethodParameter)
  end

  it "maps method splat parameters" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar *baz
        end
      end
    ))
    pin = map.first_pin('Foo#bar')
    expect(pin.parameters).to eq(['*baz'])
  end

  it "maps method block parameters" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar &block
        end
      end
    ))
    pin = map.first_pin('Foo#bar')
    expect(pin.parameters).to eq(['&block'])
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
    # expect(map.requires.map(&:name)).to include('set')
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
    expect(pin).to be_a(Solargraph::Pin::BlockParameter)
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
    expect(pin.return_type.tag).to eq('Foo')
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
    expect(pin).to be_a(Solargraph::Pin::Method)
  end

  it "maps attribute aliases" do
    smap = Solargraph::SourceMap.load_string(%(
      class Foo
        attr_accessor :bar
        alias baz bar
      end
    ))
    pin = smap.pins.select{|p| p.path == 'Foo#baz'}.first
    expect(pin).to be_a(Solargraph::Pin::Attribute)
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
    expect(pin).to be_a(Solargraph::Pin::Method)
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
    expect(pin).to be_a(Solargraph::Pin::Method)
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
    expect(pin.assignment).to be_a(Parser::AST::Node)
  end

  it "maps alias methods to attributes" do
    smap = Solargraph::SourceMap.load_string(%(
      class MyClass
        attr_accessor :foo
        alias_method :bar, :foo
      end
    ))
    pin = smap.pins.select{|p| p.path == 'MyClass#bar'}.first
    expect(pin).to be_a(Solargraph::Pin::Attribute)
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
end
