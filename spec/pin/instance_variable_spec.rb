describe Solargraph::Pin::InstanceVariable do
  # @todo Refactor
  it "detects instance variables by scope" do
  #   api_map = Solargraph::ApiMap.new
  #   source = Solargraph::Source.load_string(%(
  #     class Foo
  #       def bar
  #         @bar = 'string'
  #         @bar
  #       end
  #       @bar = [1,2,3]
  #       @bar
  #     end
  #   ), 'file.rb')
  #   api_map.virtualize source
  #   ifrag = source.fragment_at(4, 14)
  #   ipin = ifrag.complete(api_map).pins.select{|pin| pin.name == '@bar'}.first
  #   expect(ipin.return_type).to eq('String')
  #   expect(ipin.scope).to eq(:instance)
  #   cfrag = source.fragment_at(7, 12)
  #   cpin = cfrag.complete(api_map).pins.select{|pin| pin.name == '@bar'}.first
  #   expect(cpin.return_type).to eq('Array')
  #   expect(cpin.scope).to eq(:class)
  end

  it "is a kind of variable" do
    source = Solargraph::Source.load_string("@foo = 'foo'", 'file.rb')
    pin = source.instance_variable_pins.first
    expect(pin.kind).to eq(Solargraph::Pin::INSTANCE_VARIABLE)
    expect(pin.completion_item_kind).to eq(Solargraph::LanguageServer::CompletionItemKinds::VARIABLE)
    expect(pin.symbol_kind).to eq(Solargraph::LanguageServer::SymbolKinds::VARIABLE)
  end
end
