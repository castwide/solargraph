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
    source = Solargraph::Source.new(%(
      class Foo
        include Direct
        xyz.include Indirect
        xyz(include Indirect)
      end
    ))
    map = Solargraph::SourceMap.map(source)
    foo_pin = map.pins.select{|pin| pin.path == 'Foo'}.first
    expect(foo_pin.include_references.map(&:name)).to include('Direct')
    expect(foo_pin.include_references.map(&:name)).not_to include('Indirect')
  end

  it "ignores extend calls that are not attached to the current namespace" do
    source = Solargraph::Source.new(%(
      class Foo
        extend Direct
        xyz.extend Indirect
        xyz(extend Indirect)
      end
    ))
    map = Solargraph::SourceMap.map(source)
    foo_pin = map.pins.select{|pin| pin.path == 'Foo'}.first
    expect(foo_pin.extend_references.map(&:name)).to include('Direct')
    expect(foo_pin.extend_references.map(&:name)).not_to include('Indirect')
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
    pin = map.first_pin('Sub')
    expect(pin.superclass_reference.name).to eq('Sup')
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
    expect(pin.extend_references.map(&:name)).to include('Foo')
  end

  it "maps require calls" do
    map = Solargraph::SourceMap.load_string(%(
      require 'set'
    ))
    expect(map.requires.map(&:name)).to include('set')
  end

  it "maps block parameters" do
    map = Solargraph::SourceMap.load_string(%(
      x.each do |y|
      end
    ))
    pin = map.locals.select{|p| p.name == 'y'}.first
    expect(pin).to be_a(Solargraph::Pin::BlockParameter)
  end
end
