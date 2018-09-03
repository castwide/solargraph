describe Solargraph::SourceMap::Chain::Call do
  it "recognizes core methods that return subtypes" do
    api_map = Solargraph::ApiMap.new
    source_map = Solargraph::SourceMap.load_string(%(
      # @type [Array<String>]
      arr = []
      arr.first
    ))
    chain = Solargraph::SourceMap::SourceChainer.chain(source_map, Solargraph::Position.new(3, 11))
    type = chain.infer(api_map, Solargraph::ComplexType::ROOT, source_map.locals)
    expect(type.tag).to eq('String')
  end

  it "recognizes core methods that return self" do
    api_map = Solargraph::ApiMap.new
    source_map = Solargraph::SourceMap.load_string(%(
      arr = []
      arr.clone
    ))
    chain = Solargraph::SourceMap::SourceChainer.chain(source_map, Solargraph::Position.new(2, 11))
    type = chain.infer(api_map, Solargraph::ComplexType::ROOT, source_map.locals)
    expect(type.tag).to eq('Array')
  end
end
