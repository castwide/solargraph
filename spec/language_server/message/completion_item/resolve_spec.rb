describe Solargraph::LanguageServer::Message::CompletionItem::Resolve do
  it "returns MarkupContent for documentation" do
    pin = Solargraph::Pin::Method.new(
      location: nil,
      closure: Solargraph::Pin::Namespace.new(name: 'Foo'),
      name: 'bar',
      comments: 'A method',
      scope: :instance,
      visibility: :public,
      args: []
    )
    host = double(Solargraph::LanguageServer::Host, locate_pins: [pin], probe: pin.detail)
    resolve = Solargraph::LanguageServer::Message::CompletionItem::Resolve.new(host, {
      'params' => pin.completion_item
    })
    resolve.process
    expect(resolve.result[:documentation][:kind]).to eq('markdown')
    expect(resolve.result[:documentation][:value]).to include('A method')
  end

  it "returns nil documentation for empty strings" do
    pin = Solargraph::Pin::Method.new(
      location: nil,
      closure: Solargraph::Pin::Namespace.new(name: 'Foo'),
      name: 'bar',
      comments: '',
      scope: :instance,
      visibility: :public,
      args: []
    )
    host = double(Solargraph::LanguageServer::Host, locate_pins: [pin], probe: pin.detail)
    resolve = Solargraph::LanguageServer::Message::CompletionItem::Resolve.new(host, {
      'params' => pin.completion_item
    })
    resolve.process
    expect(resolve.result[:documentation]).to be_nil
  end
end
