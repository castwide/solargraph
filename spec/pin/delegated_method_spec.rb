# frozen_string_literal: true

require 'pry'

describe Solargraph::Pin::DelegatedMethod do
  it 'can be constructed from a Method pin' do
    method_pin = Solargraph::Pin::Method.new(comments: '@return [Hash{String => String}]')

    delegation_pin = described_class.new(method: method_pin, scope: :instance)
    expect(delegation_pin.return_type.to_s).to eq('Hash{String => String}')
  end

  it 'can be constructed from a receiver source and method name' do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      class Class1
        # @return [String]
        def name; end
      end

      class Class2
        # @return [Class1]
        def collaborator; end
      end
    ))
    api_map.map source

    class2 = api_map.get_path_pins('Class2').first

    chain = Solargraph::Source::Chain.new([Solargraph::Source::Chain::Call.new('collaborator', nil)])
    pin = described_class.new(
      closure: class2,
      scope: :instance,
      name: 'name',
      receiver: chain
    )

    pin.probe(api_map)

    expect(pin.return_type.to_s).to eq('String')
  end

  it 'does not overflow the stack on a delegation to the class' do
    source = Solargraph::Source.load_string(%(
      require 'forwardable'

      class Foo
        extend Forwardable

        def_delegator :class, :bar

        # @return [String]
        def self.bar
          'bar'
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source

    pin = api_map.get_method_stack('Foo', 'bar').first

    expect { pin.typify(api_map) }.not_to raise_error
  end

  it 'leaves delegations that lead back to each other undefined' do
    source = Solargraph::Source.load_string(%(
      require 'forwardable'

      class Foo
        extend Forwardable

        def_delegator :itself, :bar, :baz
        def_delegator :itself, :baz, :bar
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source

    pin = api_map.get_method_stack('Foo', 'bar').first

    expect(pin.probe(api_map)).to be_undefined
  end

  context 'with a delegation pin that has no location' do
    # Adds `Foo#bar` delegated to `class`, the way solargraph-rails maps `delegate :bar, to: :class`
    let(:convention) do
      Class.new(Solargraph::Convention::Base) do
        def local source_map
          foo = source_map.pins.find { |pin| pin.path == 'Foo' }
          return Solargraph::Environ.new unless foo

          chain = Solargraph::Source::Chain.new([Solargraph::Source::Chain::Call.new('class', nil)])
          Solargraph::Environ.new(pins: [
                                    Solargraph::Pin::DelegatedMethod.new(closure: foo, scope: :instance, name: 'bar',
                                                                         receiver: chain)
                                  ])
        end
      end
    end

    before { Solargraph::Convention.register convention }

    after { Solargraph::Convention.unregister convention }

    it 'does not overflow the stack finding its location' do
      api_map = Solargraph::ApiMap.new
      api_map.map Solargraph::Source.load_string(%(
        class Foo
          # @return [String]
          def self.bar; end
        end
      ), 'test.rb')
      pin = api_map.get_method_stack('Foo', 'bar').first
      pin.typify(api_map)

      expect { pin.type_location }.not_to raise_error
    end
  end
end
