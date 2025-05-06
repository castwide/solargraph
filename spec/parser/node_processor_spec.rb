describe Solargraph::Parser::NodeProcessor do
  it 'ignores bare private_constant calls' do
    node = Solargraph::Parser.parse(%(
      class Foo
        private_constant
      end
    ))
    expect {
      Solargraph::Parser::NodeProcessor.process(node)
    }.not_to raise_error
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
end
