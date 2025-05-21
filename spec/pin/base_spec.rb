describe Solargraph::Pin::Base do
  let(:zero_location) { Solargraph::Location.new('test.rb', Solargraph::Range.from_to(0, 0, 0, 0)) }
  let(:one_location) { Solargraph::Location.new('test.rb', Solargraph::Range.from_to(0, 0, 1, 0)) }

  it "will not combine pins with directive changes" do
    pin1 = Solargraph::Pin::Base.new(location: zero_location, name: 'Foo', comments: 'A Foo class')
    pin2 = Solargraph::Pin::Base.new(location: zero_location, name: 'Foo', comments: '@!macro my_macro')
    expect(pin1.nearly?(pin2)).to be(false)
    # enable asserts
    with_env_var('SOLARGRAPH_ASSERTS', 'on') do
      expect { pin1.combine_with(pin2) }.to raise_error(RuntimeError, /Inconsistent :macros values/)
    end
  end

  it "will not combine pins with different directives" do
    pin1 = Solargraph::Pin::Base.new(location: zero_location, name: 'Foo', comments: '@!macro my_macro')
    pin2 = Solargraph::Pin::Base.new(location: zero_location, name: 'Foo', comments: '@!macro other')
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
end
