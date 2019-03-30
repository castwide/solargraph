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

  it "detects block parameter return self from core methods" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      String.new.tap do |str|
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

  it "detects near equivalents" do
    map1 = Solargraph::SourceMap.load_string(%(
      strings.each do |foo|
      end
    ))
    pin1 = map1.locals.select{|p| p.name == 'foo'}.first
    map2 = Solargraph::SourceMap.load_string(%(
      # A minor comment change
      strings.each do |foo|
      end
      ))
    pin2 = map2.locals.select{|p| p.name == 'foo'}.first
    expect(pin1.nearly?(pin2)).to be(true)
  end

  it "infers fully qualified namespaces" do
    source = Solargraph::Source.load_string(%(
      class Foo
        class Bar
          # @return [Array<Bar>]
          def baz; end
        end
      end
      Foo::Bar.new.baz.each do |par|
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    pin = api_map.source_map('test.rb').locals.select{|p| p.name == 'par'}.first
    type = pin.typify(api_map)
    expect(type.namespace).to eq('Foo::Bar')
  end

  it "merges near equivalents" do
    loc = Solargraph::Location.new('test.rb', Solargraph::Range.from_to(0, 0, 0, 0))
    block = Solargraph::Pin::Block.new(loc, 'Foo', '', '', nil, nil)
    pin1 = Solargraph::Pin::BlockParameter.new(nil, 'Foo', 'bar', '', block)
    pin2 = Solargraph::Pin::BlockParameter.new(nil, 'Foo', 'bar', 'a comment', block)
    expect(pin1.try_merge!(pin2)).to be(true)
  end

  it "does not merge block parameters from different blocks" do
    loc = Solargraph::Location.new('test.rb', Solargraph::Range.from_to(0, 0, 0, 0))
    block1 = Solargraph::Pin::Block.new(loc, 'Foo', '', '', nil, nil)
    block2 = Solargraph::Pin::Block.new(loc, 'Bar', '', '', nil, nil)
    pin1 = Solargraph::Pin::BlockParameter.new(nil, 'Foo', 'bar', '', block1)
    pin2 = Solargraph::Pin::BlockParameter.new(nil, 'Foo', 'bar', 'a comment', block2)
    expect(pin1.try_merge!(pin2)).to be(false)
  end

  it "infers undefined types by default" do
    source = Solargraph::Source.load_string(%(
      func do |foo|
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    pin = api_map.source_map('test.rb').locals.select{|p| p.is_a?(Solargraph::Pin::BlockParameter)}.first
    # expect(pin.infer(api_map)).to be_undefined
    expect(pin.typify(api_map)).to be_undefined
    expect(pin.probe(api_map)).to be_undefined
  end
end
