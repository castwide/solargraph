describe Solargraph::Pin::Base do
  let(:zero_location) { Solargraph::Location.new('test.rb', Solargraph::Range.from_to(0, 0, 0, 0)) }
  let(:one_location) { Solargraph::Location.new('test.rb', Solargraph::Range.from_to(0, 0, 1, 0)) }

  it "will not combine pins with directive changes" do
    pin1 = Solargraph::Pin::Base.new(location: zero_location, name: 'Foo', comments: 'A Foo class',
                                     source: :yardoc, closure: Solargraph::Pin::ROOT_PIN)
    pin2 = Solargraph::Pin::Base.new(location: zero_location, name: 'Foo', comments: '@!macro my_macro',
                                     source: :yardoc, closure: Solargraph::Pin::ROOT_PIN)
    expect(pin1.nearly?(pin2)).to be(false)
    # enable asserts
    with_env_var('SOLARGRAPH_ASSERTS', 'on') do
      expect { pin1.combine_with(pin2) }.to raise_error(RuntimeError, /Inconsistent :macros count/)
    end
  end

  it "will not combine pins with different directives" do
    pin1 = Solargraph::Pin::Base.new(location: zero_location, name: 'Foo', comments: '@!macro my_macro',
                                     source: :yardoc, closure: Solargraph::Pin::ROOT_PIN)
    pin2 = Solargraph::Pin::Base.new(location: zero_location, name: 'Foo', comments: '@!macro other',
                                     source: :yardoc, closure: Solargraph::Pin::ROOT_PIN)
    expect(pin1.nearly?(pin2)).to be(false)
    with_env_var('SOLARGRAPH_ASSERTS', 'on') do
      expect { pin1.combine_with(pin2) }.to raise_error(RuntimeError, /Inconsistent :macros values/)
    end
  end

  it "sees tag differences as not near or equal" do
    pin1 = Solargraph::Pin::Base.new(location: zero_location, name: 'Foo', comments: '@return [Foo]')
    pin2 = Solargraph::Pin::Base.new(location: zero_location, name: 'Foo', comments: '@return [Bar]')
    expect(pin1.nearly?(pin2)).to be(false)
    expect(pin1 == pin2).to be(false)
  end

  it "sees comment differences as nearly but not equal" do
    pin1 = Solargraph::Pin::Base.new(location: zero_location, name: 'Foo', comments: 'A Foo class')
    pin2 = Solargraph::Pin::Base.new(location: zero_location, name: 'Foo', comments: 'A different Foo')
    expect(pin1.nearly?(pin2)).to be(true)
    expect(pin1 == pin2).to be(false)
  end

  it "recognizes deprecated tags" do
    pin = Solargraph::Pin::Base.new(location: zero_location, name: 'Foo', comments: '@deprecated Use Bar instead.')
    expect(pin).to be_deprecated
  end

  it "does not link documentation for undefined return types" do
    pin = Solargraph::Pin::Base.new(name: 'Foo', comments: '@return [undefined]')
    expect(pin.link_documentation).to eq('Foo')
  end

  it 'deals well with known closure combination issue' do
    Solargraph::Shell.new.uncache('yard')
    api_map = Solargraph::ApiMap.load_with_cache('.', $stderr)
    pins = api_map.get_method_stack('YARD::Docstring', 'parser', scope: :class)
    expect(pins.length).to eq(1)
    parser_method_pin = pins.first
    return_type = parser_method_pin.typify(api_map)
    expect(parser_method_pin.closure.name).to eq("Docstring")
    expect(parser_method_pin.closure.gates).to eq(["YARD::Docstring", "YARD", ''])
    expect(return_type).to be_defined
    expect(parser_method_pin.typify(api_map).rooted_tags).to eq('::YARD::DocstringParser')
  end
end
