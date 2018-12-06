require 'parser/current'

describe Solargraph::Source::NodeMethods do
  it "unpacks constant nodes into strings" do
    ast = Parser::CurrentRuby.parse("Foo::Bar")
    expect(Solargraph::Source::NodeMethods.unpack_name(ast)).to eq "Foo::Bar"
  end

  it "infers literal strings" do
    ast = Parser::CurrentRuby.parse("x = 'string'")
    expect(Solargraph::Source::NodeMethods.infer_literal_node_type(ast.children[1])).to eq 'String'
  end

  it "infers literal hashes" do
    ast = Parser::CurrentRuby.parse("x = {}")
    expect(Solargraph::Source::NodeMethods.infer_literal_node_type(ast.children[1])).to eq 'Hash'
  end

  it "infers literal arrays" do
    ast = Parser::CurrentRuby.parse("x = []")
    expect(Solargraph::Source::NodeMethods.infer_literal_node_type(ast.children[1])).to eq 'Array'
  end

  it "infers literal integers" do
    ast = Parser::CurrentRuby.parse("x = 100")
    expect(Solargraph::Source::NodeMethods.infer_literal_node_type(ast.children[1])).to eq 'Integer'
  end

  it "infers literal floats" do
    ast = Parser::CurrentRuby.parse("x = 10.1")
    expect(Solargraph::Source::NodeMethods.infer_literal_node_type(ast.children[1])).to eq 'Float'
  end

  it "unpacks a multi-part constant" do
    ast = Parser::CurrentRuby.parse("class Foo::Bar;end")
    expect(Solargraph::Source::NodeMethods.const_from(ast.children[0])).to eq 'Foo::Bar'
  end

  it "resolves a constant signature from a node" do
    ast = Parser::CurrentRuby.parse('String.new(foo)')
    expect(Solargraph::Source::NodeMethods.resolve_node_signature(ast)).to eq('String.new')
  end

  it "resolves a method signature from a node" do
    ast = Parser::CurrentRuby.parse('foo(1).bar.bong(2)')
    expect(Solargraph::Source::NodeMethods.resolve_node_signature(ast)).to eq('foo.bar.bong')
  end

  it "resolves a local variable signature from a node" do
    ast = Parser::CurrentRuby.parse('foo = bar; foo.bar(1).baz(2)')
    expect(Solargraph::Source::NodeMethods.resolve_node_signature(ast.children[1])).to eq('foo.bar.baz')
  end

  it "handles return nodes with implicit nil values" do
    node = Solargraph::Source.parse(%(
      return if true
    ))
    expect {
      Solargraph::Source::NodeMethods.returns_from(node)
    }.not_to raise_error
  end

  it "handles return nodes with implicit nil values" do
    node = Solargraph::Source.parse(%(
      return bla if true
    ))
    expect {
      Solargraph::Source::NodeMethods.returns_from(node)
    }.not_to raise_error
  end

  it "handles return nodes in reduceable (begin) nodes" do
    node = Solargraph::Source.parse(%(
      begin
        return if true
      end
    ))
    expect {
      Solargraph::Source::NodeMethods.returns_from(node)
    }.not_to raise_error
  end

  it "handles return nodes after other nodes" do
    node = Solargraph::Source.parse(%(
      x = 1
      return x
    ))
    expect {
      Solargraph::Source::NodeMethods.returns_from(node)
    }.not_to raise_error
  end

  it "handles return nodes with unreachable code" do
    node = Solargraph::Source.parse(%(
      x = 1
      return x
      y
    ))
    expect {
      Solargraph::Source::NodeMethods.returns_from(node)
    }.not_to raise_error
  end

  it "handles conditional returns with following code" do
    node = Solargraph::Source.parse(%(
      x = 1
      return x if foo
      y
    ))
    expect {
      Solargraph::Source::NodeMethods.returns_from(node)
    }.not_to raise_error
  end

  it "handles return nodes with reduceable code" do
    node = Solargraph::Source.parse(%(
      return begin
        x if foo
        y
      end
    ))
    expect {
      Solargraph::Source::NodeMethods.returns_from(node)
    }.not_to raise_error
  end
end
