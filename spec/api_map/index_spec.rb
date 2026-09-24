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
      first_parameter = method_pin.signatures.first.parameters.first
      expect(first_parameter.return_type.tag).to eq('String')
    end

    it 'overrides #initialize method in signature' do
      method_pin = output_pins.find { |pin| pin.path == 'Foo#initialize' }
      first_parameter = method_pin.signatures.first.parameters.first
      expect(first_parameter.return_type.tag).to eq('String')
    end

    it 'resyncs #initialize comments to match its overridden docstring' do
      method_pin = output_pins.find { |pin| pin.path == 'Foo#initialize' }
      expect(method_pin.comments).to eq("#{method_pin.docstring.to_raw}\n")
    end

    it 'resyncs .new comments to match its overridden docstring' do
      method_pin = output_pins.find { |pin| pin.path == 'Foo.new' }
      expect(method_pin.comments).to eq("#{method_pin.docstring.to_raw}\n")
    end

    context 'when the override targets a pin class that is not a method' do
      let(:input_pins) do
        [foo_class,
         Solargraph::Pin::Constant.new(name: 'BAR', closure: foo_class),
         Solargraph::Pin::Reference::Override.from_comment('Foo::BAR', '@deprecated use something else')]
      end

      it 'applies the override instead of raising on a pin that cannot take new comments' do
        constant_pin = output_pins.find { |pin| pin.path == 'Foo::BAR' }
        expect(constant_pin.docstring.tag(:deprecated)).not_to be_nil
      end
    end
  end

  describe '#map_overrides on pins that declare a source' do
    let(:sourced_class) do
      Solargraph::Pin::Namespace.new(name: 'Sourced', source: :core_fill)
    end

    let(:sourced_method) do
      Solargraph::Pin::Method.new(name: 'run', scope: :instance, parameters: [],
                                  closure: sourced_class, source: :core_fill)
    end

    let(:sourced_override) do
      Solargraph::Pin::Reference::Override.from_comment('Sourced#run', '@return [String]',
                                                        source: :core_fill)
    end

    let(:input_pins) { [sourced_class, sourced_method, sourced_override] }

    it 'gives the pin it synthesizes for the override a source' do
      original = ENV.fetch('SOLARGRAPH_ASSERTS', nil)
      ENV['SOLARGRAPH_ASSERTS'] = 'on'
      expect { output_pins }.not_to raise_error
    ensure
      ENV['SOLARGRAPH_ASSERTS'] = original
    end
  end

  describe '#map_overrides on a method alias' do
    let(:aliasing_class) do
      Solargraph::Pin::Namespace.new(name: 'Aliasing', source: :core_fill)
    end

    let(:aliased_method) do
      Solargraph::Pin::Method.new(name: 'module_eval', scope: :instance, parameters: [],
                                  closure: aliasing_class, source: :core_fill)
    end

    let(:alias_pin) do
      Solargraph::Pin::MethodAlias.new(name: 'class_eval', original: 'module_eval',
                                       scope: :instance, closure: aliasing_class,
                                       source: :core_fill)
    end

    let(:alias_override) do
      Solargraph::Pin::Reference::Override.from_comment('Aliasing#class_eval',
                                                        '@yieldreceiver [::Class<self>]',
                                                        source: :core_fill)
    end

    let(:input_pins) { [aliasing_class, aliased_method, alias_pin, alias_override] }

    it 'keeps the name of the method the alias points at' do
      combined = output_pins.find { |pin| pin.path == 'Aliasing#class_eval' }
      expect(combined.original).to eq('module_eval')
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

  # The signatures of an RBS-sourced method live only on the pin -- the
  # docstring cannot express them -- so an override must refine that set
  # rather than rebuild it from the docstring alone.
  describe '#map_overrides on a method whose signatures came from RBS' do
    let(:collection) do
      Solargraph::Pin::Namespace.new(name: 'Collection')
    end

    let(:first) do
      meth = Solargraph::Pin::Method.new(name: 'first',
                                         scope: :instance,
                                         parameters: [],
                                         closure: collection,
                                         signatures: [])
      count = Solargraph::Pin::Parameter.new(name: 'count',
                                             closure: meth,
                                             return_type: Solargraph::ComplexType.parse('Integer'))
      meth.signatures << Solargraph::Pin::Signature.new(parameters: [],
                                                        return_type: Solargraph::ComplexType.parse('String'),
                                                        closure: meth,
                                                        source: :rbs)
      meth.signatures << Solargraph::Pin::Signature.new(parameters: [count],
                                                        return_type: Solargraph::ComplexType.parse('Array<String>'),
                                                        closure: meth,
                                                        source: :rbs)
      meth
    end

    let(:first_override) do
      Solargraph::Pin::Reference::Override.from_comment('Collection#first', <<~COMMENT)
        @overload first(count)
          @param count [Symbol]
          @return [Array<Symbol>]
      COMMENT
    end

    let(:input_pins) do
      [
        collection,
        first,
        first_override
      ]
    end

    it 'keeps the RBS signature whose arity the override did not describe' do
      method_pin = output_pins.find { |pin| pin.path == 'Collection#first' }
      expect(method_pin.signatures.map { |sig| sig.return_type.tag }).to eq(['Array<Symbol>', 'String'])
    end
  end

  # A method that defines a macro is cached by name before overrides run, and
  # process_macros matches that cache against the store by pin equality.
  describe '#map_overrides on a method that defines a macro' do
    let(:macro_owner) { Solargraph::Pin::Namespace.new(name: 'Widget') }

    let(:define_thing) do
      Solargraph::Pin::Method.new(name: 'define_thing', scope: :class, closure: macro_owner,
                                  comments: "@!macro thing\n  @return [String]")
    end

    let(:input_pins) do
      [
        macro_owner,
        define_thing,
        Solargraph::Pin::Reference::Override.from_comment('Widget.define_thing', '@return [Symbol]')
      ]
    end

    it 'points the macro cache at the pin the override produced' do
      index = described_class.new(input_pins)
      overridden = index.pins.find { |pin| pin.path == 'Widget.define_thing' }
      expect(index.macro_method_name_pins['define_thing']).to include(overridden)
    end
  end
end
