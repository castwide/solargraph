# frozen_string_literal: true

describe Solargraph::Parser::NodeProcessor do
  def parse source
    Solargraph::Parser.parse(source, 'file.rb', 0)
  end

  it 'ignores bare private_constant calls' do
    node = parse(%(
      class Foo
        private_constant
      end
    ))
    expect do
      described_class.process(node)
    end.not_to raise_error
  end

  it 'orders optional args correctly' do
    node = parse(%(
      def foo(bar = nil, baz = nil); end
    ))
    pins, = described_class.process(node)
    # Method pin is first pin after default namespace
    pin = pins[1]
    expect(pin.parameters.map(&:name)).to eq(%w[bar baz])
  end

  it 'understands +=' do
    node = parse(%(
      detail = ''
      detail += "foo"
      detail.strip!
    ))
    _, vars = described_class.process(node)

    # ensure we parsed the += correctly and won't report an unexpected
    # nil assignment

    assignment = vars[0]
    expect(assignment.assignment).not_to be_nil

    reassignment = vars[1]
    expect(reassignment.assignment).not_to be_nil
  end

  it 'allows multiple processors for the same node type' do
    dummy_processor1 = Class.new(Solargraph::Parser::NodeProcessor::Base) do
      def process
        pins.push Solargraph::Pin::Method.new(name: 'foo')
      end
    end

    dummy_processor2 = Class.new(Solargraph::Parser::NodeProcessor::Base) do
      def process
        pins.push Solargraph::Pin::Method.new(name: 'bar')
      end
    end

    described_class.register(:def, dummy_processor1)
    described_class.register(:def, dummy_processor2)
    node = parse(%(
      def some_method; end
    ))
    pins, = described_class.process(node)
    # empty namespace pin is root namespace
    expect(pins.map(&:name)).to contain_exactly('', 'foo', 'bar', 'some_method')

    # Clean up the registered processors
    described_class.deregister(:def, dummy_processor1)
    described_class.deregister(:def, dummy_processor2)
  end

  it 'parses RBS parameters for classes' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo < Array #[String]
      end
    ), 'test.rb')

    expect(map.pins.last.type.to_s).to eq('Array<String>')
  end

  it 'translates RBS parameter syntax on a superclass into Solargraph syntax' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo < Array #[Hash[String, Integer]]
      end
    ), 'test.rb')

    expect(map.pins.last.type.to_s).to eq('Array<Hash{String => Integer}>')
  end

  it 'ignores bracketed comments in the class body' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo < Array
        # [:b, { c: :d }]
      end
    ), 'test.rb')

    expect(map.pins.last.type.to_s).to eq('Array')
  end

  it 'ignores a bracketed comment separated from the hash' do
    map = Solargraph::SourceMap.load_string(%(
      class Foo < Array # [String]
      end
    ), 'test.rb')

    expect(map.pins.last.type.to_s).to eq('Array')
  end

  # @param code [String]
  # @param klass [Class<Solargraph::Pin::Reference>]
  # @return [String]
  def mixin_type_for code, klass
    map = Solargraph::SourceMap.load_string(code, 'test.rb')
    map.pins.find { |pin| pin.instance_of?(klass) }.type.to_s
  end

  it 'parses RBS parameters for included modules' do
    expect(mixin_type_for(%(
      class Foo
        include Bar #[String]
      end
    ), Solargraph::Pin::Reference::Include)).to eq('Bar<String>')
  end

  it 'parses RBS parameters for prepended modules' do
    expect(mixin_type_for(%(
      class Foo
        prepend Bar #[String]
      end
    ), Solargraph::Pin::Reference::Prepend)).to eq('Bar<String>')
  end

  it 'parses RBS parameters for extended modules' do
    expect(mixin_type_for(%(
      class Foo
        extend Bar #[String]
      end
    ), Solargraph::Pin::Reference::Extend)).to eq('Bar<String>')
  end

  it 'translates RBS parameter syntax on mixins into Solargraph syntax' do
    expect(mixin_type_for(%(
      class Foo
        include Bar #[Hash[String, Integer]]
      end
    ), Solargraph::Pin::Reference::Include)).to eq('Bar<Hash{String => Integer}>')
  end

  it 'ignores a bracketed mixin comment separated from the hash' do
    expect(mixin_type_for(%(
      class Foo
        include Bar # [String]
      end
    ), Solargraph::Pin::Reference::Include)).to eq('Bar')
  end

  it 'ignores mixin parameters when one call mixes in several modules' do
    # RBS rejects this too, as "Mixing multiple modules with one call is
    # not supported", since the parameters could apply to either module.
    expect(mixin_type_for(%(
      class Foo
        include Bar, Baz #[String]
      end
    ), Solargraph::Pin::Reference::Include)).to eq('Bar')
  end

  it 'ignores mixin parameters that RBS cannot parse as a type' do
    expect(mixin_type_for(%(
      class Foo
        include Bar #[def]
      end
    ), Solargraph::Pin::Reference::Include)).to eq('Bar')
  end
end
