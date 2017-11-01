describe Solargraph::ApiMap::Source do
  it "finds require calls" do
    code = %(
      require 'solargraph'
    )
    source = Solargraph::ApiMap::Source.virtual('file.rb', code)
    expect(source.required).to include('solargraph')
  end

  it "ignores dynamic require calls" do
    code = %(
      path = 'solargraph'
      require path
    )
    source = Solargraph::ApiMap::Source.virtual('file.rb', code)
    expect(source.required.length).to eq(0)
  end

  it "finds attributes in YARD directives" do
    code = %(
      class Foo
        # @!attribute [r] bar
        #   @return [String]
      end
    )
    source = Solargraph::ApiMap::Source.virtual('file.rb', code)
    expect(source.attribute_pins.length).to eq(1)
    expect(source.attribute_pins[0].name).to eq('bar')
    expect(source.attribute_pins[0].return_type).to eq('String')
  end

  it "finds methods in YARD directives" do
    code = %(
      class Foo
        # @!method bar
        #   @return [String]
      end
    )
    source = Solargraph::ApiMap::Source.virtual('file.rb', code)
    expect(source.method_pins.length).to eq(1)
    expect(source.method_pins[0].name).to eq('bar')
    expect(source.method_pins[0].return_type).to eq('String')
  end

  it "pins global variables" do
    code = %(
      $foo = 'foo'
    )
    source = Solargraph::ApiMap::Source.virtual('file.rb', code)
    expect(source.global_variable_pins.length).to eq(1)
    expect(source.global_variable_pins[0].name).to eq('$foo')
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
    source = Solargraph::ApiMap::Source.virtual('file.rb', code)
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
    source = Solargraph::ApiMap::Source.virtual('file.rb', code)
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
    source = Solargraph::ApiMap::Source.virtual('file.rb', code)
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
    source = Solargraph::ApiMap::Source.virtual('file.rb', code)
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
    source = Solargraph::ApiMap::Source.virtual('file.rb', code)
    expect(source.namespaces).to include('Foo')
    expect(source.namespaces).to include('Foo::Bar')
    expect(source.namespaces).to include('Baz')
  end

  it "gets pins for local variables" do
    code = %(
      # @type [Hash]
      foo = method_one
      # @type [String]
      bar ||= method_two
    )
    source = Solargraph::ApiMap::Source.virtual('file.rb', code)
    expect(source.local_variable_pins.length).to eq(2)
    expect(source.local_variable_pins[0].name).to eq('foo')
    expect(source.local_variable_pins[0].return_type).to eq('Hash')
    expect(source.local_variable_pins[1].name).to eq('bar')
    expect(source.local_variable_pins[1].return_type).to eq('String')
  end
end
