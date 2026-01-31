describe Solargraph::Parser do
  def parse source
    Solargraph::Parser.parse(source, 'file.rb', 0)
  end

  it "parses nodes" do
    node = parse('class Foo; end')
    expect(Solargraph::Parser.is_ast_node?(node)).to be(true)
  end

  it 'raises repairable SyntaxError for unknown encoding errors' do
    code = "# encoding: utf-\nx = 'y'"
    expect { parse(code) }.to raise_error(Solargraph::Parser::SyntaxError)
  end
end
