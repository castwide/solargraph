describe Solargraph::Parser do
  it "parses nodes" do
    node = Solargraph::Parser.parse('class Foo; end', 'test.rb')
    expect(Solargraph::Parser.is_ast_node?(node)).to be(true)
  end

  it 'raises repairable SyntaxError for unknown encoding errors' do
    code = "# encoding: utf-\nx = 'y'"
    expect { Solargraph::Parser.parse(code) }.to raise_error(Solargraph::Parser::SyntaxError)
  end

  describe '#force_new_parser' do
    after do
      Solargraph::Parser.force_new_parser :current
    end
  
    it 'should handle :current' do
      Solargraph::Parser.force_new_parser :current
      expect(Solargraph::Parser.version).to eql(RUBY_VERSION.split('.')[..1].join.to_i)
    end

    it 'should fall back to using :current in case of bad input' do
      Solargraph::Parser.force_new_parser 'not a version string'
      expect(Solargraph::Parser.version).to eql(RUBY_VERSION.split('.')[..1].join.to_i)
    end

    it 'should use modern parser for supported versions' do
      Solargraph::Parser.force_new_parser '3.4.4'
      expect(Solargraph::Parser.version).to eql(34)
      expect(Solargraph::Parser.parser).to be_a(Prism::Translation::Parser)
    end

    it 'should use legacy parser for when modern parser cannot be used' do
      Solargraph::Parser.force_new_parser '2.7.4'
      expect(Solargraph::Parser.version).to eql(27)
      expect(Solargraph::Parser.parser).to be_a(Parser::Ruby27)
    end
  end

  describe 'different versions' do
    after do
      Solargraph::Parser.force_new_parser :current
    end

    it 'fails to parser ruby 3 syntax when using ruby 2 parsing' do
      Solargraph::Parser.force_new_parser('2.7')
    
      expect(Solargraph::Parser.version).to eql(27)
      expect { Solargraph::Parser.parse('def available? = !@internal.any?') }.to raise_error(Solargraph::Parser::SyntaxError)
    end

    it 'succeeds in parsing ruby 3 syntax when using ruby 3 parsing' do
      Solargraph::Parser.force_new_parser('3.3')

      expect(Solargraph::Parser.version).to eql(33)
      node = Solargraph::Parser.parse('def available? = !@internal.any?', 'test.rb')
      expect(Solargraph::Parser.is_ast_node?(node)).to be(true)
    end
  end
end
