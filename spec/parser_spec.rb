describe Solargraph::Parser do
  it "parses nodes" do
    node = Solargraph::Parser.parse('class Foo; end', 'test.rb')
    expect(Solargraph::Parser.is_ast_node?(node)).to be(true)
  end
end
