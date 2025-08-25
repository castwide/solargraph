describe Solargraph::Parser do
  it 'parses nodes' do
    node = Solargraph::Parser.parse('class Foo; end', 'test.rb')
    expect(Solargraph::Parser.is_ast_node?(node)).to be(true)
  end

  it 'raises repairable SyntaxError for unknown encoding errors' do
    code = "# encoding: utf-\nx = 'y'"
    expect { Solargraph::Parser.parse(code) }.to raise_error(Solargraph::Parser::SyntaxError)
  end
end
