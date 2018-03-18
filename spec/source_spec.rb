describe Solargraph::Source do
  it "allows escape sequences incompatible with UTF-8" do
    node, comments = Solargraph::Source.parse('
      x = " Un bUen café \x92"
      puts x
    ')
    expect(node).to be_kind_of(AST::Node)
  end
end
