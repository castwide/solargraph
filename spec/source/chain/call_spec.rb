describe Solargraph::Source::Chain::Call do
  it "recognizes core methods that return subtypes" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      # @type [Array<String>]
      arr = []
      arr.first
    ))
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(3, 11))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map(nil).locals)
    expect(type.tag).to eq('String')
  end

  it "recognizes core methods that return self" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      arr = []
      arr.clone
    ))
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(2, 11))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map(nil).locals)
    expect(type.tag).to eq('Array')
  end

  it "adds virtual constructors for <Class>.new calls with conflicting return types" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      class Foo
        def self.new; end
      end
      Foo.new
    ))
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(4, 11))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map(nil).locals)
    expect(type.tag).to eq('Foo')
  end

  it "infers types from macros" do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @!macro
        #   @return [$1]
        def self.bar; end
      end
      Foo.bar(String)
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map(source)
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(6, 10))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(type.tag).to eq('String')
  end

  it 'infers parameterized types' do
    source = Solargraph::Source.load_string(%(
      # @type [Array<String>]
      list = array_of_strings
      list.reverse
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    chain = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(3, 11))
    type = chain.infer(api_map, Solargraph::Pin::ROOT_PIN, api_map.source_map('test.rb').locals)
    expect(type.tag).to eq('Array<String>')
  end
end
