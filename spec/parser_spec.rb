# frozen_string_literal: true

describe Solargraph::Parser do
  def parse source
    Solargraph::Parser.parse(source, 'file.rb', 0)
  end

  it 'parses into RuboCop AST nodes' do
    node = parse('class Foo; def bar; end; end')
    expect(node).to be_a(RuboCop::AST::ClassNode)
    expect(node.body).to be_a(RuboCop::AST::DefNode)
    expect(node.body.parent).to equal(node)
  end

  it 'parses nodes' do
    node = parse('class Foo; end')
    expect(described_class.is_ast_node?(node)).to be(true)
  end

  it 'raises repairable SyntaxError for unknown encoding errors' do
    code = "# encoding: utf-\nx = 'y'"
    expect { parse(code) }.to raise_error(Solargraph::Parser::SyntaxError)
  end
end
