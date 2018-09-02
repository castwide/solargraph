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
    fragment.chain
    expect(fragment.chain).not_to be_a(Solargraph::SourceMap::Chain::Literal)
    fragment = map.fragment_at(Solargraph::Position.new(0, 1))
    expect(fragment.chain.links.first).to be_a(Solargraph::SourceMap::Chain::Literal)
    expect(fragment.chain.links.first.word).to eq('<String>')
  end
end
