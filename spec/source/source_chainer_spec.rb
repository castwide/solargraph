describe Solargraph::Source::SourceChainer do
  it "handles trailing colons that are not namespace separators" do
    source = Solargraph::Source.load_string('Foo:')
    map = Solargraph::SourceMap.map(source)
    cursor = map.cursor_at(Solargraph::Position.new(0, 4))
    expect(cursor.chain.links.first).to be_undefined
  end

  it "recognizes literal strings" do
    map = Solargraph::SourceMap.load_string("'string'")
    cursor = map.cursor_at(Solargraph::Position.new(0, 0))
    expect(cursor.chain).not_to be_a(Solargraph::Source::Chain::Literal)
    cursor = map.cursor_at(Solargraph::Position.new(0, 1))
    expect(cursor.chain.links.first).to be_a(Solargraph::Source::Chain::Literal)
    expect(cursor.chain.links.first.word).to eq('<String>')
  end

  it "recognizes literal integers" do
    map = Solargraph::SourceMap.load_string("100")
    cursor = map.cursor_at(Solargraph::Position.new(0, 0))
    expect(cursor.chain).not_to be_a(Solargraph::Source::Chain::Literal)
    cursor = map.cursor_at(Solargraph::Position.new(0, 1))
    expect(cursor.chain.links.first).to be_a(Solargraph::Source::Chain::Literal)
    expect(cursor.chain.links.first.word).to eq('<Integer>')
  end

  it "recognizes literal regexps" do
    map = Solargraph::SourceMap.load_string("/[a-z]/")
    cursor = map.cursor_at(Solargraph::Position.new(0, 0))
    expect(cursor.chain.links.first).to be_a(Solargraph::Source::Chain::Literal)
    expect(cursor.chain.links.first.word).to eq('<Regexp>')
  end

  it "recognizes class variables" do
    map = Solargraph::SourceMap.load_string('@@foo')
    cursor = map.cursor_at(Solargraph::Position.new(0, 0))
    expect(cursor.chain.links.first).to be_a(Solargraph::Source::Chain::ClassVariable)
    expect(cursor.chain.links.first.word).to eq('@@foo')
  end

  it "recognizes instance variables" do
    map = Solargraph::SourceMap.load_string('@foo')
    cursor = map.cursor_at(Solargraph::Position.new(0, 0))
    expect(cursor.chain.links.first).to be_a(Solargraph::Source::Chain::InstanceVariable)
    expect(cursor.chain.links.first.word).to eq('@foo')
  end

  it "recognizes global variables" do
    map = Solargraph::SourceMap.load_string('$foo')
    cursor = map.cursor_at(Solargraph::Position.new(0, 0))
    expect(cursor.chain.links.first).to be_a(Solargraph::Source::Chain::GlobalVariable)
    expect(cursor.chain.links.first.word).to eq('$foo')
  end

  it "recognizes constants" do
    map = Solargraph::SourceMap.load_string('Foo::Bar')
    cursor = map.cursor_at(Solargraph::Position.new(0, 6))
    expect(cursor.chain).to be_constant
    expect(cursor.chain.links.map(&:word)).to eq(['Foo::Bar'])
  end

  it "recognizes unfinished constants" do
    map = Solargraph::SourceMap.load_string('Foo:: $something')
    cursor = map.cursor_at(Solargraph::Position.new(0, 5))
    expect(cursor.chain).to be_constant
    expect(cursor.chain.links.map(&:word)).to eq(['Foo', '<undefined>'])
    expect(cursor.chain).to be_undefined
  end

  it "recognizes unfinished calls" do
    orig = Solargraph::Source.load_string('foo.bar')
    updater = Solargraph::Source::Updater.new(nil, 1, [
      Solargraph::Source::Change.new(Solargraph::Range.from_to(0, 7, 0, 7), '.')
    ])
    source = orig.synchronize(updater)
    map = Solargraph::SourceMap.map(source)
    cursor = map.cursor_at(Solargraph::Position.new(0, 8))
    expect(cursor.chain.links.last).to be_a(Solargraph::Source::Chain::Call)
    expect(cursor.chain.links.map(&:word)).to eq(['foo', 'bar', '<undefined>'])
    expect(cursor.chain).to be_undefined
  end

  it "chains signatures with square brackets" do
    map = Solargraph::SourceMap.load_string('foo[0].bar')
    cursor = map.cursor_at(Solargraph::Position.new(0, 8))
    expect(cursor.chain.links.map(&:word)).to eq(['foo', '[]', 'bar'])
  end

  it "chains signatures with curly brackets" do
    map = Solargraph::SourceMap.load_string('foo{|x| x == y}.bar')
    cursor = map.cursor_at(Solargraph::Position.new(0, 16))
    expect(cursor.chain.links.map(&:word)).to eq(['foo', 'bar'])
  end

  it "chains signatures with parentheses" do
    map = Solargraph::SourceMap.load_string('foo(x, y).bar')
    cursor = map.cursor_at(Solargraph::Position.new(0, 10))
    expect(cursor.chain.links.map(&:word)).to eq(['foo', 'bar'])
  end

  it "chains from repaired sources with literal strings" do
    orig = Solargraph::Source.load_string("''")
    updater = Solargraph::Source::Updater.new(
      nil,
      2,
      [
        Solargraph::Source::Change.new(
          Solargraph::Range.from_to(0, 2, 0, 2),
          '.'
        )
      ]
    )
    source = orig.synchronize(updater)
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(0, 3))
    expect(chain.links.first).to be_a(Solargraph::Source::Chain::Literal)
    expect(chain.links.length).to eq(2)
  end

  it "chains incomplete constants" do
    source = Solargraph::Source.load_string("Foo::")
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(0, 5))
    expect(chain.links.length).to eq(2)
    expect(chain.links.first).to be_a(Solargraph::Source::Chain::Constant)
    expect(chain.links.last).to be_a(Solargraph::Source::Chain::Constant)
    expect(chain.links.last).to be_undefined
  end

  it "works when source error ranges contain a nil range" do
    orig = Solargraph::Source.load_string("msg = 'msg'\nmsg", 'test.rb')
    updater = Solargraph::Source::Updater.new('test.rb', 1, [
      Solargraph::Source::Change.new(nil, "msg = 'msg'\nmsg.")
    ])
    source = orig.synchronize(updater)
    expect {
      Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(1, 4))
    }.not_to raise_error
  end

  it "stops phrases at opening brackets" do
    source = Solargraph::Source.load_string(%(
      (aa1, 2, 3)
      [bb2, 2, 3]
      {cc3, 2, 3}
    ))
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(1, 10))
    expect(chain.links.first.word).to eq('aa1')
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(2, 10))
    expect(chain.links.first.word).to eq('bb2')
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(3, 10))
    expect(chain.links.first.word).to eq('cc3')
  end

  it "chains instance variables from unsynchronized sources" do
    source = double(Solargraph::Source,
      :synchronized? => false,
      :code => '@foo.',
      :filename => 'test.rb',
      :string_at? => false,
      :comment_at? => false,
      :repaired? => false,
      :parsed? => true,
      :error_ranges => [],
      :node_at => nil
    )
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(0, 5))
    expect(chain.links.first.word).to eq('@foo')
    expect(chain.links.last.word).to eq('<undefined>')
  end

  it "chains class variables from unsynchronized sources" do
    source = double(Solargraph::Source,
      :synchronized? => false,
      :code => '@@foo.',
      :filename => 'test.rb',
      :string_at? => false,
      :comment_at? => false,
      :repaired? => false,
      :parsed? => true,
      :error_ranges => [],
      :node_at => nil
    )
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(0, 6))
    expect(chain.links.first.word).to eq('@@foo')
    expect(chain.links.last.word).to eq('<undefined>')
  end

  it "detects literals from chains in unsynchronized sources" do
    source1 = Solargraph::Source.load_string(%(
      ''
    ))
    source2 = source1.start_synchronize(Solargraph::Source::Updater.new(
      nil,
      2,
      [
        Solargraph::Source::Change.new(
          Solargraph::Range.from_to(1, 8, 1, 8),
          '.'
        )
      ]
    ))
    chain = Solargraph::Source::SourceChainer.chain(source2, Solargraph::Position.new(1, 9))
    expect(chain.links.first).to be_a(Solargraph::Source::Chain::Literal)
    expect(chain.links.first.word).to eq('<String>')
    expect(chain.links.last.word).to eq('<undefined>')
  end
end
