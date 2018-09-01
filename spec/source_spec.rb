describe Solargraph::Source do
  it "parses code" do
    code = 'class Foo;def bar;end;end'
    source = described_class.new(code)
    expect(source.code).to eq(code)
    expect(source.node).to be_a(Parser::AST::Node)
    expect(source).to be_parsed
  end

  it "fixes invalid code" do
    code = 'class Foo; def bar; x.'
    source = described_class.new(code)
    expect(source.code).to eq(code)
    expect(source.node).to be_a(Parser::AST::Node)
    expect(source).not_to be_parsed
  end

  it "finds ranges" do
    code = %(
      class Foo
        def bar
        end
      end
    )
    source = described_class.new(code)
    range = Solargraph::Source::Range.new(Solargraph::Source::Position.new(2, 8), Solargraph::Source::Position.new(2, 15))
    expect(source.at(range)).to eq('def bar')
  end

  it "finds nodes" do
    code = 'class Foo;def bar;end;end'
    source = described_class.new(code)
    node = source.node_at(0, 0)
    expect(node.type).to eq(:class)
    node = source.node_at(0, 10)
    expect(node.type).to eq(:def)
  end

  it "synchronizes from incremental updates" do
    code = 'class Foo;def bar;end;end'
    source = described_class.new(code)
    updater = Solargraph::Source::Updater.new(
      nil, 0, [Solargraph::Source::Change.new(
        Solargraph::Source::Range.new(
          Solargraph::Source::Position.new(0, 9),
          Solargraph::Source::Position.new(0, 9)
        ),
        'd'
      )]
    )
    source.synchronize updater
    expect(source.code).to start_with('class Food;')
    expect(source.node.children[0].children[1]).to eq(:Food)
  end

  it "synchronizes from full updates" do
    code1 = 'class Foo;end'
    code2 = 'class Bar;end'
    source = described_class.new(code1)
    updater = Solargraph::Source::Updater.new(nil, 0, [
      Solargraph::Source::Change.new(nil, code2)
    ])
    source.synchronize(updater)
    expect(source.code).to eq(code2)
    expect(source.node.children[0].children[1]).to eq(:Bar)
  end

  it "repairs broken incremental updates" do
    code = %(
      class Foo
        def bar
        end
      end
    )
    source = described_class.new(code)
    updater = Solargraph::Source::Updater.new(
      nil, 0, [Solargraph::Source::Change.new(
        Solargraph::Source::Range.new(
          Solargraph::Source::Position.new(3, 0),
          Solargraph::Source::Position.new(3, 1)
        ),
        '@'
      )]
    )
    source.synchronize updater
    expect(source).to be_parsed
  end

  it "flags irreparable updates" do
    code = 'class Foo;def bar;end;end'
    source = described_class.new(code)
    updater = Solargraph::Source::Updater.new(nil, 0, [
      Solargraph::Source::Change.new(nil, 'end;end')
    ])
    source.synchronize(updater)
    expect(source).not_to be_parsed
  end
end
