require 'parser/current'

describe Solargraph::NodeMethods do
  let(:test_class) {
    Class.new do
      include Solargraph::NodeMethods
    end
  }

  it "unpacks constant nodes into strings" do
    ast = Parser::CurrentRuby.parse("Foo::Bar")
    tester = test_class.new
    expect(tester.unpack_name(ast)).to eq "Foo::Bar"
  end

  it "infers literal strings" do
    ast = Parser::CurrentRuby.parse("x = 'string'")
    tester = test_class.new
    expect(tester.infer(ast.children[1])).to eq 'String'
  end

  it "infers literal hashes" do
    ast = Parser::CurrentRuby.parse("x = {}")
    tester = test_class.new
    expect(tester.infer(ast.children[1])).to eq 'Hash'
  end

  it "infers literal arrays" do
    ast = Parser::CurrentRuby.parse("x = []")
    tester = test_class.new
    expect(tester.infer(ast.children[1])).to eq 'Array'
  end

  it "unpacks a multi-part constant" do
    ast = Parser::CurrentRuby.parse("class Foo::Bar;end")
    tester = test_class.new
    expect(tester.const_from(ast.children[0])).to eq 'Foo::Bar'
  end

  it "resolves a constant signature from a node" do
    ast = Parser::CurrentRuby.parse('String.new(foo)')
    tester = test_class.new
    expect(tester.resolve_node_signature(ast)).to eq('String.new')
  end

  it "resolves a method signature from a node" do
    ast = Parser::CurrentRuby.parse('foo(1).bar.bong(2)')
    tester = test_class.new
    expect(tester.resolve_node_signature(ast)).to eq('foo.bar.bong')
  end

  it "resolves a local variable signature from a node" do
    ast = Parser::CurrentRuby.parse('foo = bar; foo.bar(1).baz(2)')
    tester = test_class.new
    expect(tester.resolve_node_signature(ast.children[1])).to eq('foo.bar.baz')
  end

  # @todo The following type inferences are the reponsibility of the ApiMap.
  
  #it "infers class instantiation" do
  #  ast = Parser::CurrentRuby.parse("x = Object.new")
  #  tester = test_class.new
  #  expect(tester.infer(ast.children[1])).to eq 'Object'
  #end

  #it "infers constants" do
  #  ast = Parser::CurrentRuby.parse("x = Class")
  #  tester = test_class.new
  #  expect(tester.infer(ast.children[1])).to eq 'Class'
  #end

  #it "infers constants with root" do
  #  ast = Parser::CurrentRuby.parse("x = ::String")
  #  tester = test_class.new
  #  expect(tester.infer(ast.children[1])).to eq 'String'
  #end

  #it "infers namespaced constants" do
  #  ast = Parser::CurrentRuby.parse("x = Foo::Bar")
  #  tester = test_class.new
  #  expect(tester.infer(ast.children[1])).to eq 'Foo::Bar'
  #end
end
