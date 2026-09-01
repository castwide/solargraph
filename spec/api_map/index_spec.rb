# frozen_string_literal: true

describe Solargraph::ApiMap::Index do
  subject(:output_pins) { described_class.new(input_pins).pins }

  describe '#map_overrides' do
    let(:foo_class) do
      Solargraph::Pin::Namespace.new(name: 'Foo')
    end

    let(:foo_initialize) do
      init = Solargraph::Pin::Method.new(name: 'initialize',
                                         scope: :instance,
                                         parameters: [],
                                         closure: foo_class)
      # no return type specified
      param = Solargraph::Pin::Parameter.new(name: 'bar',
                                             closure: init)
      init.parameters << param
      init
    end

    let(:foo_new) do
      init = Solargraph::Pin::Method.new(name: 'new',
                                         scope: :class,
                                         parameters: [],
                                         closure: foo_class)
      # no return type specified
      param = Solargraph::Pin::Parameter.new(name: 'bar',
                                             closure: init)
      init.parameters << param
      init
    end

    let(:foo_override) do
      Solargraph::Pin::Reference::Override.from_comment('Foo#initialize',
                                                        '@param [String] bar')
    end

    let(:input_pins) do
      [
        foo_initialize,
        foo_new,
        foo_override
      ]
    end

    it 'has a docstring to process on override' do
      expect(foo_override.docstring.tags).to be_empty
    end

    it 'overrides .new method' do
      method_pin = output_pins.find { |pin| pin.path == 'Foo.new' }
      first_parameter = method_pin.parameters.first
      expect(first_parameter.return_type.tag).to eq('String')
    end

    it 'overrides #initialize method in signature' do
      method_pin = output_pins.find { |pin| pin.path == 'Foo#initialize' }
      first_parameter = method_pin.parameters.first
      expect(first_parameter.return_type.tag).to eq('String')
    end
  end

  describe '#map_overrides with @overload tags' do
    let(:passthrough) do
      Solargraph::Pin::Namespace.new(name: 'Passthrough')
    end

    let(:identity) do
      meth = Solargraph::Pin::Method.new(name: 'identity',
                                         scope: :instance,
                                         parameters: [],
                                         closure: passthrough)
      param = Solargraph::Pin::Parameter.new(name: 'arguments', closure: meth)
      meth.parameters << param
      meth
    end

    let(:identity_override) do
      Solargraph::Pin::Reference::Override.from_comment('Passthrough#identity', <<~COMMENT)
        @overload identity(arguments)
          @param arguments [Array<Hash>]
          @return [Array<Hash>]
        @overload identity(arguments)
          @param arguments [Array<String>]
          @return [Array<String>]
      COMMENT
    end

    let(:input_pins) do
      [
        passthrough,
        identity,
        identity_override
      ]
    end

    it 'produces one dispatchable signature per @overload tag, not just the first' do
      method_pin = output_pins.find { |pin| pin.path == 'Passthrough#identity' }
      expect(method_pin.signatures.length).to eq(2)
      expect(method_pin.signatures.map { |sig| sig.parameters.first.return_type.tag }).to eq(['Array<Hash>', 'Array<String>'])
      expect(method_pin.signatures.map { |sig| sig.return_type.tag }).to eq(['Array<Hash>', 'Array<String>'])
    end

    context 'when overriding a method that already had its signatures computed' do
      let(:input_pins) do
        [
          passthrough,
          identity,
          identity_override
        ]
      end

      it 'still applies every @overload tag, not zero of them' do
        # Simulates #signatures already being read before the override applied.
        identity.signatures

        method_pin = output_pins.find { |pin| pin.path == 'Passthrough#identity' }
        expect(method_pin.signatures.length).to eq(2)
        expect(method_pin.signatures.map { |sig| sig.return_type.tag }).to eq(['Array<Hash>', 'Array<String>'])
      end
    end
  end

  # https://solargraph.org/guides/yard documents @!override with a bare
  # @return tag (no @overload) as its primary example, using
  # Benchmark.measure as the sample target:
  #
  #   # @!override Benchmark.measure
  #   #   @return [Benchmark::Tms]
  describe '#map_overrides with a bare @return tag' do
    let(:benchmark_module) do
      Solargraph::Pin::Namespace.new(name: 'Benchmark')
    end

    let(:measure) do
      Solargraph::Pin::Method.new(name: 'measure',
                                  scope: :class,
                                  parameters: [],
                                  closure: benchmark_module)
    end

    let(:measure_override) do
      Solargraph::Pin::Reference::Override.from_comment('Benchmark.measure', '@return [Benchmark::Tms]')
    end

    let(:input_pins) do
      [
        benchmark_module,
        measure,
        measure_override
      ]
    end

    it 'redefines the return type documented on solargraph.org' do
      method_pin = output_pins.find { |pin| pin.path == 'Benchmark.measure' }
      expect(method_pin.return_type.tag).to eq('Benchmark::Tms')
    end

    context 'when overriding a method that already had its signatures computed' do
      it 'still redefines the return type' do
        # Mirrors solargraph-rspec's @!override hitting an already-resolved pin.
        measure.signatures

        method_pin = output_pins.find { |pin| pin.path == 'Benchmark.measure' }
        expect(method_pin.return_type.tag).to eq('Benchmark::Tms')
      end
    end
  end
end
