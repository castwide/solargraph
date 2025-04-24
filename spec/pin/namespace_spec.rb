describe Solargraph::Pin::Namespace do
  it "handles long namespaces" do
    pin = Solargraph::Pin::Namespace.new(closure: Solargraph::Pin::Namespace.new(name: 'Foo'), name: 'Bar')
    expect(pin.path).to eq('Foo::Bar')
  end

  it "has class scope" do
    source = Solargraph::Source.load_string(%(
      class Foo
      end
    ))
    pin = Solargraph::Pin::Namespace.new(name: 'Foo')
    expect(pin.context.scope).to eq(:class)
  end

  it "is a kind of namespace/class/module" do
    pin1 = Solargraph::Pin::Namespace.new(name: 'Foo')
    expect(pin1.completion_item_kind).to eq(Solargraph::LanguageServer::CompletionItemKinds::CLASS)
    pin2 = Solargraph::Pin::Namespace.new(name: 'Foo', type: :module)
    expect(pin2.completion_item_kind).to eq(Solargraph::LanguageServer::CompletionItemKinds::MODULE)
  end

  it 'handles nested namespaces inside closures' do
    pin = Solargraph::Pin::Namespace.new(closure: Solargraph::Pin::Namespace.new(name: 'Foo'), name: 'Bar::Baz')
    expect(pin.namespace).to eq('Foo::Bar')
    expect(pin.name).to eq('Baz')
    expect(pin.path).to eq('Foo::Bar::Baz')
  end

  it 'uses @param tags as generic type parameters' do
    pin = Solargraph::Pin::Namespace.new(name: 'Foo', comments: '@generic GenericType')
    expect(pin.generics).to eq(['GenericType'])
    expect(pin.to_rbs).to eq('class ::Foo[GenericType]')
  end
end
