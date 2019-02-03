describe Solargraph::Pin::Attribute do
  let(:nspin) { Solargraph::Pin::Namespace.new(name: 'Foo') }
  it "is a kind of attribute/property" do
    source = Solargraph::Source.load_string(%(
      class Foo
        attr_reader :bar
      end
    ))
    map = Solargraph::SourceMap.map(source)
    pin = map.pins.select{|p| p.kind == Solargraph::Pin::ATTRIBUTE}.first
    expect(pin).not_to be_nil
    expect(pin.kind).to eq(Solargraph::Pin::ATTRIBUTE)
    expect(pin.completion_item_kind).to eq(Solargraph::LanguageServer::CompletionItemKinds::PROPERTY)
    expect(pin.symbol_kind).to eq(Solargraph::LanguageServer::SymbolKinds::PROPERTY)
  end

  it "uses return type tags" do
    pin = Solargraph::Pin::Attribute.new(closure: nspin, name: 'bar', comments: '@return [File]', access: :reader, scope: :instance)
    expect(pin.return_type.tag).to eq('File')
  end

  it "has empty parameters" do
    pin = Solargraph::Pin::Attribute.new(name: 'bar')
    expect(pin.parameters).to be_empty
    expect(pin.parameter_names).to be_empty
  end

  it "detects undefined types" do
    pin = Solargraph::Pin::Attribute.new(closure: nspin, name: 'bar', access: :reader, scope: :instance)
    expect(pin.return_type).to be_undefined
  end

  it "generates paths" do
    ipin = Solargraph::Pin::Attribute.new(closure: nspin, name: 'bar', access: :reader, scope: :instance)
    expect(ipin.path).to eq('Foo#bar')
    cpin = Solargraph::Pin::Attribute.new(closure: nspin, name: 'bar', access: :reader, scope: :class)
    expect(cpin.path).to eq('Foo.bar')
  end

  it "handles invalid return type tags" do
    pin = Solargraph::Pin::Attribute.new(closure: nspin, name: 'bar', comments: '@return [Array<]', access: :reader)
    expect(pin.return_type).to be_undefined
  end
end
