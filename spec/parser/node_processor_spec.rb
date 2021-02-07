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
end
