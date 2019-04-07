describe Solargraph::LanguageServer::Message::CompletionItem::Resolve do
  it "returns MarkupContent for documentation" do
    pin = Solargraph::Pin::Method.new(
      nil,
      'Foo',
      'bar',
      'A method',
      :instance,
      :public,
      []
    )
    host = double(Solargraph::LanguageServer::Host, locate_pins: [pin])
    resolve = Solargraph::LanguageServer::Message::CompletionItem::Resolve.new(host, {
      'params' => pin.completion_item
    })
    resolve.process
    expect(resolve.result[:documentation][:kind]).to eq('markdown')
    expect(resolve.result[:documentation][:value]).to include('A method')
  end

  it "returns nil documentation for empty strings" do
    pin = Solargraph::Pin::Method.new(
      nil,
      'Foo',
      'bar',
      '',
      :instance,
      :public,
      []
    )
    host = double(Solargraph::LanguageServer::Host, locate_pins: [pin])
    resolve = Solargraph::LanguageServer::Message::CompletionItem::Resolve.new(host, {
      'params' => pin.completion_item
    })
    resolve.process
    expect(resolve.result[:documentation]).to be_nil
  end
end
