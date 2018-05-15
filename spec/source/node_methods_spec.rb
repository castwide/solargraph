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

  # @todo The following type inferences are the reponsibility of the ApiMap.
  
  #it "infers class instantiation" do
  #  ast = Parser::CurrentRuby.parse("x = Object.new")
  #  expect(Solargraph::Source::NodeMethods.infer_literal_node_type(ast.children[1])).to eq 'Object'
  #end

  #it "infers constants" do
  #  ast = Parser::CurrentRuby.parse("x = Class")
  #  expect(Solargraph::Source::NodeMethods.infer_literal_node_type(ast.children[1])).to eq 'Class'
  #end

  #it "infers constants with root" do
  #  ast = Parser::CurrentRuby.parse("x = ::String")
  #  expect(Solargraph::Source::NodeMethods.infer_literal_node_type(ast.children[1])).to eq 'String'
  #end

  #it "infers namespaced constants" do
  #  ast = Parser::CurrentRuby.parse("x = Foo::Bar")
  #  expect(Solargraph::Source::NodeMethods.infer_literal_node_type(ast.children[1])).to eq 'Foo::Bar'
  #end
end
