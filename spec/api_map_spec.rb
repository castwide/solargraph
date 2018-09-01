describe Solargraph::ApiMap do
  before :all do
    @api_map = Solargraph::ApiMap.new
  end

  it "returns core methods" do
    pins = @api_map.get_methods('String')
    expect(pins.map(&:path)).to include('String#upcase')
  end

  it "returns core classes" do
    pins = @api_map.get_constants('')
    expect(pins.map(&:path)).to include('String')
  end

  it "indexes pins" do
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

  it "finds methods from included modules" do
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

  it "finds methods from superclasses" do
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

  it "checks method pin visibility" do
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

  it "finds nested namespaces" do
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

  it "finds nested namespaces within a context" do
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

  it "checks constant visibility" do
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

  it "includes Kernel methods in the root namespace" do
    @api_map.index []
    pins = @api_map.get_methods('')
    expect(pins.map(&:path)).to include('Kernel#puts')
  end

  it "gets instance methods for complex types" do
    @api_map.index []
    type = Solargraph::ComplexType.parse('String')
    pins = @api_map.get_complex_type_methods(type)
    expect(pins.map(&:path)).to include('String#upcase')
  end

  it "gets class methods for complex types" do
    @api_map.index []
    type = Solargraph::ComplexType.parse('Class<String>')
    pins = @api_map.get_complex_type_methods(type)
    expect(pins.map(&:path)).to include('String.try_convert')
  end

  it "checks visibility of complex type methods" do
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

  it "finds methods for duck types" do
    @api_map.index []
    type = Solargraph::ComplexType.parse('#foo, #bar')
    pins = @api_map.get_complex_type_methods(type)
    expect(pins.map(&:name)).to include('foo')
    expect(pins.map(&:name)).to include('bar')
  end

  it "finds methods for parametrized class types" do
    @api_map.index []
    type = Solargraph::ComplexType.parse('Class<String>')
    pins = @api_map.get_complex_type_methods(type)
    expect(pins.map(&:path)).to include('String.try_convert')
  end

  it "finds stacks of methods" do
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

  it "finds symbols" do
    map = Solargraph::SourceMap.load_string('sym = :sym')
    @api_map.index map.pins
    pins = @api_map.get_symbols
    expect(pins.map(&:name)).to include(':sym')
  end

  it "finds instance variables" do
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

  it "finds class variables" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        @@cvar = make_value
      end
    ))
    @api_map.index map.pins
    pins = @api_map.get_class_variable_pins('Foo')
    expect(pins.map(&:name)).to include('@@cvar')
  end

  it "finds global variables" do
    map = Solargraph::SourceMap.load_string('$foo = []')
    @api_map.index map.pins
    pins = @api_map.get_global_variable_pins
    expect(pins.map(&:name)).to include('$foo')
  end

  it "generates clips" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar; end
      end
      Foo.new.bar
    ))
    @api_map.index map.pins
    clip = @api_map.clip(map, Solargraph::Position.new(4, 15))
    expect(clip).to be_a(Solargraph::SourceMap::Clip)
  end
end
