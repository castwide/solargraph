describe Solargraph::Pin::BlockParameter do
  it "detects block parameter return types from @yieldparam tags" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      # @yieldparam [Array]
      def yielder; end
      yielder do |things|
        things
      end
    ), 'file.rb')
    api_map.map source
    clip = api_map.clip_at('file.rb', Solargraph::Position.new(4, 9))
    expect(clip.infer.tag).to eq('Array')
  end

  it "detects block parameter return types from core methods" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      String.new.split.each do |str|
        str
      end
    ), 'file.rb')
    api_map.map source
    clip = api_map.clip_at('file.rb', Solargraph::Position.new(2, 8))
    expect(clip.define.first.return_complex_type.namespace).to eq('String')
  end

  it "gets return types from param type tags" do
    map = Solargraph::SourceMap.load_string(%(
      require 'set'

      # @yieldparam [Array]
      def yielder
      end

      # @param things [Set]
      yielder do |things|
        things
      end
    ))
    expect(map.locals.first.return_type.tag).to eq('Set')
  end

  it "is a kind of block_parameter/variable" do
    source = Solargraph::Source.new(%(
      foo.bar do |baz|
      end
    ))
    map = Solargraph::SourceMap.map(source)
    block = map.pins.select{|p| p.kind == Solargraph::Pin::BLOCK}.first
    param = block.parameters.first
    expect(param.kind).to eq(Solargraph::Pin::BLOCK_PARAMETER)
    expect(param.completion_item_kind).to eq(Solargraph::LanguageServer::CompletionItemKinds::VARIABLE)
    expect(param.symbol_kind).to eq(Solargraph::LanguageServer::SymbolKinds::VARIABLE)
  end
end
