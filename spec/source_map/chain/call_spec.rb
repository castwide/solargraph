describe Solargraph::SourceMap::Chain::Call do
  it "recognizes core methods that return subtypes" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      # @type [Array<String>]
      arr = []
      arr.first
    ))
    api_map.replace source
    chain = Solargraph::SourceMap::SourceChainer.chain(source, Solargraph::Position.new(3, 11))
    type = chain.infer(api_map, Solargraph::ComplexType::ROOT, api_map.source_map(nil).locals)
    expect(type.tag).to eq('String')
  end

  it "recognizes core methods that return self" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      arr = []
      arr.clone
    ))
    api_map.replace source
    chain = Solargraph::SourceMap::SourceChainer.chain(source, Solargraph::Position.new(2, 11))
    type = chain.infer(api_map, Solargraph::ComplexType::ROOT, api_map.source_map(nil).locals)
    expect(type.tag).to eq('Array')
  end
end
