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
end
