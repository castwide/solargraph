describe Solargraph::SourceMap::SourceChainer do
  it "handles trailing colons that are not namespace separators" do
    source = Solargraph::Source.load_string('Foo:')
    map = Solargraph::SourceMap.map(source)
    fragment = map.fragment_at(Solargraph::Position.new(0, 4))
    expect(fragment.chain.links.first).to be_undefined
  end

  it "recognizes literal strings" do
    map = Solargraph::SourceMap.load_string("'string'")
    fragment = map.fragment_at(Solargraph::Position.new(0, 0))
    expect(fragment.chain).not_to be_a(Solargraph::SourceMap::Chain::Literal)
    fragment = map.fragment_at(Solargraph::Position.new(0, 1))
    expect(fragment.chain.links.first).to be_a(Solargraph::SourceMap::Chain::Literal)
    expect(fragment.chain.links.first.word).to eq('<String>')
  end

  it "recognizes class variables" do
    map = Solargraph::SourceMap.load_string('@@foo')
    fragment = map.fragment_at(Solargraph::Position.new(0, 0))
    expect(fragment.chain.links.first).to be_a(Solargraph::SourceMap::Chain::ClassVariable)
    expect(fragment.chain.links.first.word).to eq('@@foo')
  end

  it "recognizes instance variables" do
    map = Solargraph::SourceMap.load_string('@foo')
    fragment = map.fragment_at(Solargraph::Position.new(0, 0))
    expect(fragment.chain.links.first).to be_a(Solargraph::SourceMap::Chain::InstanceVariable)
    expect(fragment.chain.links.first.word).to eq('@foo')
  end

  it "recognizes global variables" do
    map = Solargraph::SourceMap.load_string('$foo')
    fragment = map.fragment_at(Solargraph::Position.new(0, 0))
    expect(fragment.chain.links.first).to be_a(Solargraph::SourceMap::Chain::GlobalVariable)
    expect(fragment.chain.links.first.word).to eq('$foo')
  end

  it "recognizes constants" do
    map = Solargraph::SourceMap.load_string('Foo::Bar')
    fragment = map.fragment_at(Solargraph::Position.new(0, 6))
    expect(fragment.chain).to be_constant
    expect(fragment.chain.links.map(&:word)).to eq(['Foo', 'Bar'])
  end

  it "recognizes unfinished constants" do
    map = Solargraph::SourceMap.load_string('Foo:: $something')
    fragment = map.fragment_at(Solargraph::Position.new(0, 5))
    expect(fragment.chain).to be_constant
    expect(fragment.chain.links.map(&:word)).to eq(['Foo', '<undefined>'])
    expect(fragment.chain).to be_undefined
  end

  it "recognizes unfinished calls" do
    map = Solargraph::SourceMap.load_string('foo.bar.')
    fragment = map.fragment_at(Solargraph::Position.new(0, 8))
    expect(fragment.chain.links.last).to be_a(Solargraph::SourceMap::Chain::Call)
    expect(fragment.chain.links.map(&:word)).to eq(['foo', 'bar', '<undefined>'])
    expect(fragment.chain).to be_undefined
  end
end
