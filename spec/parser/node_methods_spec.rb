describe Solargraph::Parser::NodeMethods do
  it "handles return nodes with implicit nil values" do
    node = Solargraph::Parser.parse(%(
      return if true
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from(node)
    # The expectation is changing from previous versions. If conditions
    # have an implicit else branch, so this node should return [nil, nil].
    expect(rets.length).to eq(2)
  end

  it "handles return nodes with implicit nil values" do
    node = Solargraph::Parser.parse(%(
      return bla if true
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from(node)
    expect(rets.length).to eq(2)
  end

  it "handles return nodes in reduceable (begin) nodes" do
    node = Solargraph::Parser.parse(%(
      begin
        return if true
      end
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from(node)
    expect(rets.length).to eq(2)
  end

  it "handles return nodes after other nodes" do
    node = Solargraph::Parser.parse(%(
      x = 1
      return x
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from(node)
    expect(rets.length).to eq(1)
  end

  it "handles return nodes with unreachable code" do
    node = Solargraph::Parser.parse(%(
      x = 1
      return x
      y
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from(node)
    expect(rets.length).to eq(1)
  end

  it "handles conditional returns with following code" do
    node = Solargraph::Parser.parse(%(
      x = 1
      return x if foo
      y
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from(node)
    # Another implicit else branch. This should have 3 return nodes.
    expect(rets.length).to eq(2)
  end

  it "handles return nodes with reduceable code" do
    node = Solargraph::Parser.parse(%(
      return begin
        x if foo
        y
      end
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from(node)
    expect(rets.length).to eq(1)
  end

  it "handles top 'and' nodes" do
    node = Solargraph::Parser.parse('1 && "2"')
    rets = Solargraph::Parser::NodeMethods.returns_from(node)
    expect(rets.length).to eq(2)
    expect(rets[0].type).to eq(:LIT)
    expect(rets[1].type).to eq(:STR)
  end

  it "handles top 'or' nodes" do
    node = Solargraph::Parser.parse('1 || "2"')
    rets = Solargraph::Parser::NodeMethods.returns_from(node)
    expect(rets.length).to eq(2)
    expect(rets[0].type).to eq(:LIT)
    expect(rets[1].type).to eq(:STR)
  end

  it "handles nested 'and' nodes" do
    node = Solargraph::Parser.parse('return 1 && "2"')
    rets = Solargraph::Parser::NodeMethods.returns_from(node)
    expect(rets.length).to eq(2)
    expect(rets[0].type).to eq(:LIT)
    expect(rets[1].type).to eq(:STR)
  end

  it "handles nested 'or' nodes" do
    node = Solargraph::Parser.parse('return 1 || "2"')
    rets = Solargraph::Parser::NodeMethods.returns_from(node)
    expect(rets.length).to eq(2)
    expect(rets[0].type).to eq(:LIT)
    expect(rets[1].type).to eq(:STR)
  end

  it 'finds return nodes in blocks' do
    node = Solargraph::Parser.parse(%(
      array.each do |item|
        return item if foo
      end
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from(node)
    expect(rets.length).to eq(2)
    expect(rets[1].type).to eq(:DVAR)
  end

  it 'returns nested return blocks' do
    node = Solargraph::Parser.parse(%(
      if foo
        array.each do |item|
          return item if foo
        end
      end
      nil
    ))
    rets = Solargraph::Parser::NodeMethods.returns_from(node)
    expect(rets.length).to eq(2)
    expect(rets[0].type).to eq(:DVAR)
  end
end
