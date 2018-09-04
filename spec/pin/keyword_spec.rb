describe Solargraph::Pin::Keyword do
  it "is a kind of keyword" do
    pin = Solargraph::Pin::Keyword.new('foo')
    expect(pin.kind).to eq(Solargraph::Pin::KEYWORD)
    expect(pin.completion_item_kind).to eq(Solargraph::LanguageServer::CompletionItemKinds::KEYWORD)
  end
end
