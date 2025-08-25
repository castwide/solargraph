describe Solargraph::Parser::NodeProcessor do
  it 'ignores bare private_constant calls' do
    node = Solargraph::Parser.parse(%(
      class Foo
        private_constant
      end
    ))
    expect do
      Solargraph::Parser::NodeProcessor.process(node)
    end.not_to raise_error
  end

  it 'orders optional args correctly' do
    node = Solargraph::Parser.parse(%(
      def foo(bar = nil, baz = nil); end
    ))
    pins, = Solargraph::Parser::NodeProcessor.process(node)
    # Method pin is first pin after default namespace
    pin = pins[1]
    expect(pin.parameters.map(&:name)).to eq(%w[bar baz])
  end

  it 'understands +=' do
    node = Solargraph::Parser.parse(%(
      detail = ''
      detail += "foo"
      detail.strip!
    ))
    _, vars = Solargraph::Parser::NodeProcessor.process(node)

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

    Solargraph::Parser::NodeProcessor.register(:def, dummy_processor1)
    Solargraph::Parser::NodeProcessor.register(:def, dummy_processor2)
    node = Solargraph::Parser.parse(%(
      def some_method; end
    ))
    pins, = Solargraph::Parser::NodeProcessor.process(node)
    # empty namespace pin is root namespace
    expect(pins.map(&:name)).to contain_exactly('', 'foo', 'bar', 'some_method')

    # Clean up the registered processors
    Solargraph::Parser::NodeProcessor.deregister(:def, dummy_processor1)
    Solargraph::Parser::NodeProcessor.deregister(:def, dummy_processor2)
  end
end
