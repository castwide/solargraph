describe Solargraph::Pin::InstanceVariable do
  it "is a kind of variable" do
    source = Solargraph::Source.load_string("@foo = 'foo'", 'file.rb')
    map = Solargraph::SourceMap.map(source)
    pin = map.pins.select{ |p| p.is_a?(Solargraph::Pin::InstanceVariable) }.first
    expect(pin.completion_item_kind).to eq(Solargraph::LanguageServer::CompletionItemKinds::VARIABLE)
    expect(pin.symbol_kind).to eq(Solargraph::LanguageServer::SymbolKinds::VARIABLE)
  end

  it "does not link documentation for undefined return types" do
    pin = Solargraph::Pin::InstanceVariable.new(name: '@bar')
    expect(pin.link_documentation).to eq('@bar')
  end
end
