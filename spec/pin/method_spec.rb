describe Solargraph::Pin::Method do
  it "tracks code parameters" do
    source = Solargraph::Source.new(%(
      def foo bar, baz = MyClass.new
      end
    ))
    map = Solargraph::SourceMap.map(source)
    pin = map.pins.select{|pin| pin.path == '#foo'}.first
    expect(pin.parameters.length).to eq(2)
    expect(pin.parameters[0]).to eq('bar')
    expect(pin.parameters[1]).to eq('baz = MyClass.new')
    expect(pin.parameter_names).to eq(%w[bar baz])
  end

  it "tracks keyword parameters" do
    source = Solargraph::Source.new(%(
      def foo bar:, baz: MyClass.new
      end
    ))
    map = Solargraph::SourceMap.map(source)
    pin = map.pins.select{|pin| pin.path == '#foo'}.first
    expect(pin.parameters.length).to eq(2)
    expect(pin.parameters[0]).to eq('bar:')
    expect(pin.parameters[1]).to eq('baz: MyClass.new')
    expect(pin.parameter_names).to eq(%w[bar baz])
  end

  it "includes param tags in documentation" do
    comments = %(
      @param one [First] description1
      @param two [Second] description2
    )
    # pin = source.pins.select{|pin| pin.path == 'Foo#bar'}.first
    pin = Solargraph::Pin::Method.new(nil, nil, nil, comments, nil, nil, [])
    expect(pin.documentation).to include('one')
    expect(pin.documentation).to include('[First]')
    expect(pin.documentation).to include('description1')
    expect(pin.documentation).to include('two')
    expect(pin.documentation).to include('[Second]')
    expect(pin.documentation).to include('description2')
  end

  it "detects return types from tags" do
    # source = Solargraph::Source.new(%(
    #   # @return [Hash]
    #   def foo bar:, baz: MyClass.new
    #   end
    # ))
    # pin = source.pins.select{|pin| pin.path == '#foo'}.first
    pin = Solargraph::Pin::Method.new(nil, nil, nil, '@return [Hash]', nil, nil, [])
    expect(pin.return_type).to eq('Hash')
  end

  # @todo method_pins is only ever used in specs
  it "is a kind of method" do
    pin = Solargraph::Pin::Method.new(nil, nil, nil, nil, nil, nil, nil)
    expect(pin.kind).to eq(Solargraph::Pin::METHOD)
    # source = Solargraph::Source.new(%(
    #   def foo; end
    # ))
    # pin = source.method_pins.first
    # expect(pin.kind).to eq(Solargraph::Pin::METHOD)
    # expect(pin.completion_item_kind).to eq(Solargraph::LanguageServer::CompletionItemKinds::METHOD)
    # expect(pin.symbol_kind).to eq(Solargraph::LanguageServer::SymbolKinds::METHOD)
  end

  it "ignores malformed return tags" do
    pin = Solargraph::Pin::Method.new(nil, 'Foo', 'bar', '@return [Array<String', :instance, :public, [])
    expect(pin.return_complex_type).to be_undefined
  end

  it "will not merge with changes in parameters" do
    pin1 = Solargraph::Pin::Method.new(nil, 'Foo', 'bar', '', :instance, :public, ['one', 'two'])
    pin2 = Solargraph::Pin::Method.new(nil, 'Foo', 'bar', '', :instance, :public, ['three'])
    expect(pin1.nearly?(pin2)).to be(false)
  end
end
