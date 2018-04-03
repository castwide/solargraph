describe Solargraph::Source do
  it "allows escape sequences incompatible with UTF-8" do
    node, comments = Solargraph::Source.parse('
      x = " Un bUen café \x92"
      puts x
    ')
    expect(node).to be_kind_of(AST::Node)
  end

  it "finds require calls" do
    code = %(
      require 'solargraph'
    )
    source = Solargraph::Source.virtual(code, 'file.rb')
    expect(source.required).to include('solargraph')
  end

  it "ignores dynamic require calls" do
    code = %(
      path = 'solargraph'
      require path
    )
    source = Solargraph::Source.virtual(code, 'file.rb')
    expect(source.required.length).to eq(0)
  end

  it "finds attributes in YARD directives" do
    code = %(
      class Foo
        # @!attribute [r] bar
        #   @return [String]
        # @!attribute baz
        # @!attribute [r,w] boo
      end
    )
    source = Solargraph::Source.virtual(code, 'file.rb')
    expect(source.attribute_pins.length).to eq(5)
    expect(source.attribute_pins[0].name).to eq('bar')
    expect(source.attribute_pins[0].return_type).to eq('String')
    names = source.attribute_pins.map(&:name)
    expect(names).not_to include('bar=')
    expect(names).to include('baz')
    expect(names).to include('baz=')
    expect(names).to include('boo')
    expect(names).to include('boo=')
  end

  it "finds methods in YARD directives" do
    code = %(
      class Foo
        # @!method bar
        #   @return [String]
      end
    )
    source = Solargraph::Source.virtual(code, 'file.rb')
    expect(source.method_pins.length).to eq(1)
    expect(source.method_pins[0].name).to eq('bar')
    expect(source.method_pins[0].return_type).to eq('String')
  end

  it "pins class variables" do
    source = Solargraph::Source.load_string(%(
      module TestModule
        @@foo = bar
      end
    ))
    expect(source.class_variable_pins.length).to eq(1)
    expect(source.class_variable_pins.first.name).to eq('@@foo')
  end

  it "pins instance variables" do
    source = Solargraph::Source.load_string(%(
      module TestModule
        @cifoo = bar
        def test_method
          @iifoo = bar
        end
      end
    ))
    expect(source.instance_variable_pins.length).to eq(2)
    expect(source.instance_variable_pins[0].name).to eq('@cifoo')
    expect(source.instance_variable_pins[0].namespace).to eq('TestModule')
    expect(source.instance_variable_pins[0].scope).to eq(:class)
    expect(source.instance_variable_pins[1].name).to eq('@iifoo')
    expect(source.instance_variable_pins[1].namespace).to eq('TestModule')
    expect(source.instance_variable_pins[1].scope).to eq(:instance)
  end

  it "pins global variables" do
    source = Solargraph::Source.load_string(%(
      $foo = bar
    ))
    expect(source.global_variable_pins.length).to eq(1)
    expect(source.global_variable_pins.first.name).to eq('$foo')
  end

  it "returns nil for unknown variable types" do
    source = Solargraph::Source.load_string(%(
      foo = bar
    ))
    expect(source.local_variable_pins.first.return_type).to eq(nil)
  end

  it "infers variable return types from @type tags" do
    source = Solargraph::Source.load_string(%(
      # @type [String]
      foo = bar
    ))
    expect(source.local_variable_pins.first.return_type).to eq('String')
  end

  it "pins namespaces" do
    source = Solargraph::Source.load_string(%(
      module Foo
        class Bar
        end
      end
    ))
    expect(source.namespace_pins.length).to eq(2)
    expect(source.namespace_pins[0].path).to eq('Foo')
    expect(source.namespace_pins[0].type).to eq(:module)
    expect(source.namespace_pins[0].return_type).to eq('Module<Foo>')
    expect(source.namespace_pins[1].path).to eq('Foo::Bar')
    expect(source.namespace_pins[1].type).to eq(:class)
    expect(source.namespace_pins[1].return_type).to eq('Class<Foo::Bar>')
  end

  it "pins class methods" do
    source = Solargraph::Source.load_string(%(
      class Foo
        def self.bar
        end
      end
    ))
    expect(source.method_pins.length).to eq(1)
    expect(source.method_pins.first.path).to eq('Foo.bar')
    expect(source.method_pins.first.scope).to eq(:class)
  end

  it "pins instance methods" do
    source = Solargraph::Source.load_string(%(
      class Foo
        def bar
        end
      end
    ))
    expect(source.method_pins.length).to eq(1)
    expect(source.method_pins.first.path).to eq('Foo#bar')
    expect(source.method_pins.first.scope).to eq(:instance)
  end

  it "detects method visibility" do
    source = Solargraph::Source.load_string(%(
      class Foo
        def a_public;end
        protected
        def a_protected;end
        private
        def a_private;end
        public
        def a_public_2;end
      end
    ))
    expect(source.method_pins[0].visibility).to eq(:public)
    expect(source.method_pins[1].visibility).to eq(:protected)
    expect(source.method_pins[2].visibility).to eq(:private)
    expect(source.method_pins[3].visibility).to eq(:public)
  end

  it "detects method return types from @return tags" do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @return [Hash]
        def bar;end
      end
    ))
    expect(source.method_pins.first.return_type).to eq('Hash')
  end

  it "detects literal values for variable return types" do
    source = Solargraph::Source.load_string('
      str = \'str\'
      dyn = "#{foo}"
      arr = []
      hsh = {}
      num = 100
      flt = 0.1
    ')
    expect(source.local_variable_pins[0].return_type).to eq('String')
    expect(source.local_variable_pins[1].return_type).to eq('String')
    expect(source.local_variable_pins[2].return_type).to eq('Array')
    expect(source.local_variable_pins[3].return_type).to eq('Hash')
    expect(source.local_variable_pins[4].return_type).to eq('Integer')
    expect(source.local_variable_pins[5].return_type).to eq('Float')
  end

  it "detects attribute reader pins" do
    source = Solargraph::Source.load_string(%(
      class Foo
        attr_reader :bar
      end
    ))
    expect(source.attribute_pins.length).to eq(1)
    expect(source.attribute_pins.first.name).to eq('bar')
    expect(source.attribute_pins.first.access).to eq(:reader)
  end

  it "detects attribute writer pins" do
    source = Solargraph::Source.load_string(%(
      class Foo
        attr_writer :bar
      end
    ))
    expect(source.attribute_pins.length).to eq(1)
    expect(source.attribute_pins.first.name).to eq('bar=')
    expect(source.attribute_pins.first.access).to eq(:writer)
  end

  it "detects attribute accessor pins" do
    source = Solargraph::Source.load_string(%(
      class Foo
        attr_accessor :bar
      end
    ))
    expect(source.attribute_pins.length).to eq(2)
    names = source.attribute_pins.map(&:name)
    expect(names).to include('bar')
    expect(names).to include('bar=')
    accessors = source.attribute_pins.map(&:access)
    expect(accessors).to include(:reader)
    expect(accessors).to include(:writer)    
  end

  it "pins method parameters as local variables" do
    source = Solargraph::Source.load_string(%(
      class Foo
        def bar baz
        end
      end
    ))
    expect(source.local_variable_pins.length).to eq(1)
    expect(source.local_variable_pins.first.name).to eq('baz')
  end

  it "pins block parameters as local variables" do
    source = Solargraph::Source.load_string(%(
      100.times do |num|
      end
    ))
    expect(source.local_variable_pins.length).to eq(1)
    expect(source.local_variable_pins.first.name).to eq('num')
  end

  it "gets method data from code and tags" do
    code = %(
      class Foo
        # @return [String]
        def bar
        end
        # @return [Hash]
        def self.baz
        end
      end
    )
    source = Solargraph::Source.virtual(code, 'file.rb')
    expect(source.method_pins.length).to eq(2)
    # @type [Solargraph::Pin::Method]
    bar = source.method_pins[0]
    expect(bar.name).to eq('bar')
    expect(bar.scope).to eq(:instance)
    expect(bar.visibility).to eq(:public)
    expect(bar.return_type).to eq('String')
    # @type [Solargraph::Pin::Method]
    baz = source.method_pins[1]
    expect(baz.name).to eq('baz')
    expect(baz.scope).to eq(:class)
    expect(baz.visibility).to eq(:public)
    expect(baz.return_type).to eq('Hash')
  end

  it "gets attribute data from code and tags" do
    code = %(
      class Foo
        # @return [String]
        attr_reader :bar
      end
    )
    source = Solargraph::Source.virtual(code, 'file.rb')
    expect(source.attribute_pins.length).to eq(1)
    # @type [Solargraph::Pin::Attribute]
    pin = source.attribute_pins[0]
    expect(pin.name).to eq('bar')
    expect(pin.return_type).to eq('String')
  end

  it "gets signatures for variables" do
    code = %(
      $foo = String.new('1,2').split(',')
    )
    source = Solargraph::Source.virtual(code, 'file.rb')
    expect(source.global_variable_pins[0].signature).to eq('String.new.split')
  end

  it "gets docstrings for pins" do
    code = %(
      class Foo
        # My method
        # @return [String]
        def bar
        end
      end
    )
    source = Solargraph::Source.virtual(code, 'file.rb')
    expect(source.method_pins[0].docstring.to_s).to eq('My method')
    expect(source.method_pins[0].docstring.tag(:return)).to be_kind_of(YARD::Tags::Tag)
  end

  it "collects namespaces" do
    code = %(
      module Foo
        class Bar
        end
      end
      module Baz;end
    )
    source = Solargraph::Source.virtual(code, 'file.rb')
    expect(source.namespaces).to include('Foo')
    expect(source.namespaces).to include('Foo::Bar')
    expect(source.namespaces).to include('Baz')
  end

  it "pins for local variables" do
    code = %(
      # @type [Hash]
      foo = method_one
      # @type [String]
      bar ||= method_two
    )
    source = Solargraph::Source.virtual(code, 'file.rb')
    expect(source.local_variable_pins.length).to eq(2)
    expect(source.local_variable_pins[0].name).to eq('foo')
    expect(source.local_variable_pins[0].return_type).to eq('Hash')
    expect(source.local_variable_pins[1].name).to eq('bar')
    expect(source.local_variable_pins[1].return_type).to eq('String')
  end

  it "pins top-level methods" do
    code = %(
      def foo(bar, baz)
      end
    )
    source = Solargraph::Source.virtual(code, 'file.rb')
    expect(source.method_pins.length).to eq(1)
    expect(source.method_pins.first.name).to eq('foo')
    expect(source.method_pins.first.parameters).to eq(['bar', 'baz'])
  end

  it "pins top-level methods from directives" do
    code = %(
      begin
      # @!method foo(bar, baz)
      #   @return [Array]
      end
    )
    source = Solargraph::Source.virtual(code, 'file.rb')
    expect(source.method_pins.length).to eq(1)
    expect(source.method_pins.first.name).to eq('foo')
    expect(source.method_pins.first.parameters).to eq(['bar', 'baz'])
    expect(source.method_pins.first.return_type).to eq('Array')
  end

  it "pins constants" do
    code = %(
      class Foo
        BAR = 'bar'
      end
    )
    source = Solargraph::Source.virtual(code, 'file.rb')
    expect(source.constant_pins.length).to eq(1)
    expect(source.constant_pins[0].kind).to eq(Solargraph::LanguageServer::CompletionItemKinds::CONSTANT)
    expect(source.constant_pins[0].return_type).to eq('String')
    expect(source.constant_pins[0].value).to eq("'bar'")
  end

  it "sets correct scope and visibility for class methods" do
    code = %(
      class Foo
        private_class_method def self.bar
        end
        private
        def self.baz
        end
      end
    )
    source = Solargraph::Source.virtual(code, 'file.rb')
    expect(source.method_pins.length).to eq(2)
    expect(source.method_pins[0].scope).to eq(:class)
    expect(source.method_pins[0].visibility).to eq(:private)
    expect(source.method_pins[1].scope).to eq(:class)
    expect(source.method_pins[1].visibility).to eq(:public)
  end

  it "sets visibility for private_class_method symbol argument" do
    code = %(
      class Foo
        def self.bar
        end
        private_class_method :bar
      end
    )
    source = Solargraph::Source.virtual(code, 'file.rb')
    expect(source.method_pins.length).to eq(1)
    expect(source.method_pins[0].scope).to eq(:class)
    expect(source.method_pins[0].visibility).to eq(:private)
  end

  it "sets visibility for private_class_method string argument" do
    code = %(
      class Foo
        def self.bar
        end
        private_class_method 'bar'
      end
    )
    source = Solargraph::Source.virtual(code, 'file.rb')
    expect(source.method_pins.length).to eq(1)
    expect(source.method_pins[0].scope).to eq(:class)
    expect(source.method_pins[0].visibility).to eq(:private)
  end

  it "sets visibility for constants" do
    code = %(
      module Foobar
        PUBLIC_CONST = ''
        PRIVATE_CONST = ''
        class PublicClass
        end
        class PrivateClass
        end
        private_constant :PRIVATE_CONST
        private_constant :PrivateClass
      end
    )
    source = Solargraph::Source.virtual(code, 'file.rb')
    pub_const = source.constant_pins.select{|p| p.name == 'PUBLIC_CONST'}.first
    expect(pub_const.visibility).to eq(:public)
    priv_const = source.constant_pins.select{|p| p.name == 'PRIVATE_CONST'}.first
    expect(priv_const.visibility).to eq(:private)
    pub_class = source.namespace_pins.select{|p| p.name == 'PublicClass'}.first
    expect(pub_class.visibility).to eq(:public)
    priv_class = source.namespace_pins.select{|p| p.name == 'PrivateClass'}.first
    expect(priv_class.visibility).to eq(:private)
  end
end
