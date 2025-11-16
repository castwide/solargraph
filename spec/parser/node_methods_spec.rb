# These tests are deliberately generic because they apply to both the Legacy
# and Rubyvm node methods.
describe Solargraph::Parser::NodeMethods do
  def parse source
    Solargraph::Parser.parse(source, 'test.rb', 0)
  end

  it "unpacks constant nodes into strings" do
    ast = parse("Foo::Bar")
    expect(Solargraph::Parser::NodeMethods.unpack_name(ast)).to eq "Foo::Bar"
  end

  it "infers literal strings" do
    ast = parse("x = 'string'")
    expect(Solargraph::Parser::NodeMethods.infer_literal_node_type(ast.children[1])).to eq '::String'
  end

  it "infers literal hashes" do
    ast = parse("x = {}")
    expect(Solargraph::Parser::NodeMethods.infer_literal_node_type(ast.children[1])).to eq '::Hash'
  end

  it "infers literal arrays" do
    ast = parse("x = []")
    expect(Solargraph::Parser::NodeMethods.infer_literal_node_type(ast.children[1])).to eq '::Array'
  end

  it "infers literal integers" do
    ast = parse("x = 100")
    expect(Solargraph::Parser::NodeMethods.infer_literal_node_type(ast.children[1])).to eq '::Integer'
  end

  it "infers literal floats" do
    ast = parse("x = 10.1")
    expect(Solargraph::Parser::NodeMethods.infer_literal_node_type(ast.children[1])).to eq '::Float'
  end

  it "infers literal symbols" do
    ast = parse(":symbol")
    expect(Solargraph::Parser::NodeMethods.infer_literal_node_type(ast)).to eq '::Symbol'
  end

  it "infers double quoted symbols" do
    ast = parse(':"symbol"')
    expect(Solargraph::Parser::NodeMethods.infer_literal_node_type(ast)).to eq '::Symbol'
  end

  it "infers interpolated double quoted symbols" do
    ast = parse(':"#{Object}"')
    expect(Solargraph::Parser::NodeMethods.infer_literal_node_type(ast)).to eq '::Symbol'
  end

  it "infers single quoted symbols" do
    ast = parse(":'symbol'")
    expect(Solargraph::Parser::NodeMethods.infer_literal_node_type(ast)).to eq '::Symbol'
  end

  it 'infers literal booleans' do
    true_ast = parse("true")
    expect(Solargraph::Parser::NodeMethods.infer_literal_node_type(true_ast)).to eq '::Boolean'
    false_ast = parse("false")
    expect(Solargraph::Parser::NodeMethods.infer_literal_node_type(false_ast)).to eq '::Boolean'
  end

  it "handles return nodes with implicit nil values" do
    node = parse(%(
      return if true
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    # @todo Should there be two returns, the second being nil?
    expect(rets.map(&:to_s)).to eq(['(nil)', '(nil)'])
    expect(rets.length).to eq(2)
  end

  it "handles return nodes with implicit nil values" do
    node = parse(%(
      return bla if true
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    # Two returns, the second being implicit nil
    expect(rets.length).to eq(2)
  end

  it 'handles return nodes from case statements' do
    node = parse(%(
      case x
      when 100
        true
      end
    ))
    returns = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    # Include an implicit `nil` for missing else
    expect(returns.map(&:to_s)).to eq(['(true)', '(nil)'])
  end

  it 'handles return nodes from case statements with else' do
    node = parse(%(
      case x
      when 100, 125
        true
      when 500
        73
      when 23
        false
      when 12
        nil
      else
        if 1 == 2
          false
        else
          true
        end
      end
    ))
    returns = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(returns.length).to eq(6)
    expect(returns.map(&:to_s)).to eq(['(true)', '(int 73)', '(false)', '(nil)', '(false)', '(true)'])
  end

  it 'handles return nodes from case statements with boolean conditions' do
    node = parse(%(
      case true
      when x
        true
      else
        false
      end
    ))
    returns = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(returns.length).to eq(2)
  end

  it "handles return nodes in reduceable (begin) nodes" do
    # @todo Temporarily disabled. Result is 3 nodes instead of 2.
    # node = parse(%(
    #   begin
    #     return if true
    #   end
    # ))
    # rets = Solargraph::Parser::NodeMethods.returns_from(node)
    # expect(rets.length).to eq(2)
  end

  it "handles return nodes after other nodes" do
    node = parse(%(
      x = 1
      return x
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.length).to eq(1)
  end

  it "handles return nodes with unreachable code" do
    node = parse(%(
      x = 1
      return x
      y
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.length).to eq(1)
  end

  it "handles conditional returns with following code" do
    node = parse(%(
      x = 1
      return x if foo
      y
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.length).to eq(2)
  end

  it "handles return nodes with reduceable code" do
    node = parse(%(
      return begin
        x if foo
        y
      end
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.length).to eq(1)
  end

  it "handles top 'and' nodes" do
    node = parse('1 && "2"')
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.length).to eq(1)
    expect(rets[0].type.to_s.downcase).to eq('and')
  end

  it "handles top 'or' nodes" do
    node = parse('1 || "2"')
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.length).to eq(1)
  end

  it "handles nested 'and' nodes" do
    node = parse('return 1 && "2"')
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.length).to eq(1)
    expect(rets[0].type.to_s.downcase).to eq('and')
  end

  it "handles nested 'or' nodes" do
    node = parse('return 1 || "2"')
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.length).to eq(2)
    expect(Solargraph::Parser::NodeMethods.infer_literal_node_type(rets[0])).to eq('::Integer')
    expect(Solargraph::Parser::NodeMethods.infer_literal_node_type(rets[1])).to eq('::String')
  end

  it 'finds return nodes in blocks' do
    node = parse(%(
      array.each do |item|
        return item if foo
      end
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.map(&:type)).to eq([:block, :lvar])
  end

  it 'finds correct return node line in begin expressions' do
    node = parse(%(
      begin
        123
        '123'
      end
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.map(&:type)).to eq([:str])
  end

  it 'returns nested return blocks' do
    node = parse(%(
      if foo
        array.each do |item|
          return item if foo
        end
      end
      nil
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.map(&:type)).to eq([:lvar, :nil])
  end

  it "handles return nodes with implicit nil values" do
    node = parse(%(
      return if true
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    # The expectation is changing from previous versions. If conditions
    # have an implicit else branch, so this node should return [nil, nil].
    expect(rets.length).to eq(2)
  end

  it "handles return nodes with implicit nil values" do
    node = parse(%(
      return bla if true
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.map(&:type)).to eq([:send, :nil])
  end

  it "handles return nodes in reduceable (begin) nodes" do
    # @todo Temporarily disabled. Result is 3 nodes instead of 2 in legacy.
    # node = parse(%(
    #   begin
    #     return if true
    #   end
    # ))
    # rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    # expect(rets.length).to eq(2)
  end

  it "handles return nodes after other nodes" do
    node = parse(%(
      x = 1
      return x
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.map(&:type)).to eq([:lvar])
  end

  it "handles return nodes with unreachable code" do
    node = parse(%(
      x = 1
      return x
      y
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.length).to eq(1)
  end

  xit "short-circuits return node finding after a raise statement in a begin expressiona" do
    node = parse(%(
      raise "Error"
      y
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.length).to eq(0)
  end

  it "does not short circuit return node finding after a raise statement in a conditional" do
    node = parse(%(
      x = 1
      raise "Error" if foo
      y
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.length).to eq(1)
  end

  it "does not short circuit return node finding after a return statement in a conditional" do
    node = parse(%(
      x = 1
      return "Error" if foo
      y
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.length).to eq(2)
  end

  it "handles return nodes with reduceable code" do
    node = parse(%(
      return begin
        x if foo
        y
      end
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.length).to eq(1)
  end

  it "handles top 'and' nodes" do
    node = parse('1 && "2"')
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.map(&:type)).to eq([:and])
  end

  it "handles top 'or' nodes" do
    node = parse('1 || "2"')
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.map(&:type)).to eq([:or])
  end

  it "handles nested 'and' nodes from return" do
    node = parse('return 1 && "2"')
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.map(&:type)).to eq([:and])
  end

  it "handles nested 'or' nodes from return" do
    node = parse('return 1 || "2"')
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.map(&:type)).to eq([:int, :str])
  end

  it 'finds return nodes in blocks' do
    node = parse(%(
      array.each do |item|
        return item if foo
      end
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.map(&:type)).to eq([:block, :lvar])
    # expect(rets[1].type).to eq(:DVAR)
  end

  it 'returns nested return blocks' do
    node = parse(%(
      if foo
        array.each do |item|
          return item if foo
        end
      end
      nil
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.map(&:type)).to eq([:lvar, :nil])
    # expect(rets[0].type).to eq(:DVAR)
  end

  it 'handles return nodes from case statements' do
    node = parse(%(
      case 1
      when 1 then ""
      else
        ""
      end
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.map(&:type)).to eq([:str, :str])
  end

  it 'handles return nodes from case statements without else' do
    node = parse(%(
      case 1
      when 1
        ""
      end
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.map(&:type)).to eq([:str, :nil])
  end

  it 'handles return nodes from case statements with super' do
    node = parse(%(
      case other
      when Docstring
        Docstring.new([all, other.all].join("\n"), object)
      else
        super
      end
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from_method_body(node)
    expect(rets.map(&:type)).to eq([:send, :zsuper])
  end

  describe 'convert_hash' do
    it 'converts literal hash arguments' do
      node = parse('{foo: :bar}')
      hash = Solargraph::Parser::NodeMethods.convert_hash(node)
      expect(hash.keys).to eq([:foo])
    end

    it 'ignores call arguments' do
      node = parse('some_call')
      hash = Solargraph::Parser::NodeMethods.convert_hash(node)
      expect(hash).to eq({})
    end
  end

  describe 'call_nodes_from' do
    it 'handles super calls' do
      source = Solargraph::Source.load_string(%(
        class Foo
          def super_with_block
            super { |record| }
          end
        end
      ))
      calls = Solargraph::Parser::NodeMethods.call_nodes_from(source.node)
      expect(calls).to be_one
    end

    it 'handles chained calls' do
      source = Solargraph::Source.load_string(%(
        Foo.new.bar('string')
      ))
      calls = Solargraph::Parser::NodeMethods.call_nodes_from(source.node)
      expect(calls.length).to eq(2)
    end

    it 'handles calls from inside array literals' do
      source = Solargraph::Source.load_string(%(
        [ Foo.new.bar('string') ]
      ))
      calls = Solargraph::Parser::NodeMethods.call_nodes_from(source.node)
      expect(calls.length).to eq(2)
    end

    it 'handles calls from inside array literals that are chained' do
      source = Solargraph::Source.load_string(%(
        [ Foo.new.bar('string') ].compact
      ))
      calls = Solargraph::Parser::NodeMethods.call_nodes_from(source.node)
      expect(calls.length).to eq(3)
    end

    it 'does not over-report calls' do
      source = Solargraph::Source.load_string(%(
        class Foo
          def something
          end
        end
        class Bar < Foo
          def something
            super(1) + 2
          end
        end
      ))
      calls = Solargraph::Parser::NodeMethods.call_nodes_from(source.node)
      expect(calls.length).to eq(2)
    end
  end
end
