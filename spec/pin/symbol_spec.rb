describe Solargraph::Pin::Symbol do
  context "as an unquoted literal" do
    it "is a kind of keyword" do
      pin = Solargraph::Pin::Symbol.new(nil, ':symbol')
      expect(pin.completion_item_kind).to eq(Solargraph::LanguageServer::CompletionItemKinds::KEYWORD)
    end

    it "has a Symbol return type" do
      pin = Solargraph::Pin::Symbol.new(nil, ':symbol')
      expect(pin.return_type.tag).to eq('Symbol')
    end
  end

  context "as a double quoted literal" do
    it "is a kind of keyword" do
      pin = Solargraph::Pin::Symbol.new(nil, ':"symbol"')
      expect(pin.completion_item_kind).to eq(Solargraph::LanguageServer::CompletionItemKinds::KEYWORD)
    end

    it "has a Symbol return type" do
      pin = Solargraph::Pin::Symbol.new(nil, ':"symbol"')
      expect(pin.return_type.tag).to eq('Symbol')
    end
  end

  context "as a double quoted interpolatd literal" do
    it "is a kind of keyword" do
      pin = Solargraph::Pin::Symbol.new(nil, ':"symbol #{variable}"')
      expect(pin.completion_item_kind).to eq(Solargraph::LanguageServer::CompletionItemKinds::KEYWORD)
    end

    it "has a Symbol return type" do
      pin = Solargraph::Pin::Symbol.new(nil, ':"symbol #{variable}"')
      expect(pin.return_type.tag).to eq('Symbol')
    end
  end


  context "as a single quoted literal" do
    it "is a kind of keyword" do
      pin = Solargraph::Pin::Symbol.new(nil, ":'symbol'")
      expect(pin.completion_item_kind).to eq(Solargraph::LanguageServer::CompletionItemKinds::KEYWORD)
    end

    it "has a Symbol return type" do
      pin = Solargraph::Pin::Symbol.new(nil, ":'symbol'")
      expect(pin.return_type.tag).to eq('Symbol')
    end
  end
end
