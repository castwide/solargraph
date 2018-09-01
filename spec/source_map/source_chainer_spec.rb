describe Solargraph::SourceMap::SourceChainer do
  it "handles trailing colons that are not namespace separators" do
    source = Solargraph::Source.load_string('Foo:')
    map = Solargraph::SourceMap.map(source)
    fragment = map.fragment_at(Solargraph::Position.new(0, 4))
    expect(fragment.chain.links.first).to be_undefined
  end
end
