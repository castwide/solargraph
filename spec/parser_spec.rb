describe Solargraph::Parser do
  it "parses nodes" do
    node = Solargraph::Parser.parse('class Foo; end', 'test.rb')
    expect(node).to be_a(Parser::AST::Node)
  end
end
