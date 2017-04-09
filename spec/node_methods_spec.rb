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
