describe Solargraph::YardMap::Macro do
  it 'generates pins for overloads that have no method directive' do
    source = Solargraph::Source.load_string(%(
      class Example
        # @!macro make_method
        #   @overload $1
        #   @overload $1(num)
        #     @param num [Integer]
        def self.make_method name
        end

        make_method :sym
      end
    ), 'test.rb')
    map = Solargraph::ApiMap.new
    map.map source
    pin = map.get_path_pins('Example#sym').first
    expect(pin).not_to be_nil
    expect(pin.signatures.length).to eq(2)
    expect(pin.signatures[0].parameters.map(&:name)).to eq([])
    expect(pin.signatures[1].parameters.map(&:name)).to eq(['num'])
    expect(pin.signatures[1].parameters.first.return_type.tag).to eq('Integer')
  end

  it 'generates class methods when the macro sets the scope' do
    source = Solargraph::Source.load_string(%(
      class Example
        # @!macro make_method
        #   @!scope class
        #   @overload $1
        #   @overload $1(num)
        #     @param num [Integer]
        def self.make_method name
        end

        make_method :sym
      end
    ), 'test.rb')
    map = Solargraph::ApiMap.new
    map.map source
    pin = map.get_path_pins('Example.sym').first
    expect(pin).not_to be_nil
    expect(pin.scope).to eq(:class)
    expect(pin.signatures.length).to eq(2)
  end

  it 'resolves methods generated from overloads in macros' do
    source = Solargraph::Source.load_string(%(
      class Example
        # @!macro make_method
        #   @overload $1
        #   @overload $1(num)
        #     @param num [Integer]
        def self.make_method name
        end

        make_method :sym
      end

      Example.new.sym
    ), 'test.rb')
    map = Solargraph::ApiMap.new
    map.map source
    clip = map.clip_at('test.rb', Solargraph::Position.new(12, 19))
    expect(clip.define.first.path).to eq('Example#sym')
  end

  it 'adds the comments on the macro call to the generated pin' do
    source = Solargraph::Source.load_string(%(
      class Example
        # @!macro make_method
        #   @overload $1
        def self.make_method name
        end

        # The generated method.
        # @return [String]
        make_method :sym
      end
    ), 'test.rb')
    map = Solargraph::ApiMap.new
    map.map source
    pin = map.get_path_pins('Example#sym').first
    expect(pin).not_to be_nil
    expect(pin.docstring.all.to_s).to include('The generated method.')
    expect(pin.typify(map).tag).to eq('String')
  end

  it 'does not generate a second pin when the macro defines a method' do
    source = Solargraph::Source.load_string(%(
      class Example
        # @!macro prop
        #   @!method $1(value)
        #     @return [$2]
        #   @overload $1
        def self.property name, type
        end

        property :foo, String
      end
    ), 'test.rb')
    map = Solargraph::ApiMap.new
    map.map source
    expect(map.get_methods('Example').count { |pin| pin.name == 'foo' }).to eq(1)
  end
end
