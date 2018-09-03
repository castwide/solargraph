describe Solargraph::Pin::Constant do
  it "resolves constant paths" do
    source = Solargraph::Source.new(%(
      class Foo
        BAR = 'bar'
      end
    ))
    map = Solargraph::SourceMap.map(source)
    pin = map.pins.select{|pin| pin.name == 'BAR'}.first
    expect(pin.path).to eq('Foo::BAR')
  end

  it "is a constant kind" do
    source = Solargraph::Source.new(%(
      class Foo
        BAR = 'bar'
      end
    ))
    map = Solargraph::SourceMap.map(source)
    pin = map.pins.select{|pin| pin.name == 'BAR'}.first
    expect(pin.kind).to eq(Solargraph::Pin::CONSTANT)
    expect(pin.completion_item_kind).to eq(Solargraph::LanguageServer::CompletionItemKinds::CONSTANT)
    expect(pin.symbol_kind).to eq(Solargraph::LanguageServer::SymbolKinds::CONSTANT)
  end
end
