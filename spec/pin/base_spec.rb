describe Solargraph::Pin::Base do
  let(:zero_location) { Solargraph::Location.new('test.rb', Solargraph::Range.from_to(0, 0, 0, 0)) }
  let(:one_location) { Solargraph::Location.new('test.rb', Solargraph::Range.from_to(0, 0, 1, 0)) }

  # @todo namespace_pins and method_pins are only ever used in specs
  it "returns its location in the source" do
    # source = Solargraph::Source.load_string(%(
    #   class Foo
    #     def bar
    #     end
    #   end
    # ), 'file.rb')
    # source.namespace_pins.each do |pin|
    #   expect(pin.location).not_to be_nil
    # end
    # source.method_pins.each do |pin|
    #   expect(pin.location).not_to be_nil
    # end
  end

  it "merges pins with location changes" do
    pin1 = Solargraph::Pin::Base.new(zero_location, '', 'Foo', '')
    pin2 = Solargraph::Pin::Base.new(one_location, '', 'Foo', '')
    expect(pin1.try_merge!(pin2)).to eq(true)
    expect(pin1.location).to eq(one_location)
  end

  it "merges pins with comment changes" do
    pin1 = Solargraph::Pin::Base.new(zero_location, '', 'Foo', 'A Foo class')
    merge_comment = 'A modified Foo class'
    pin2 = Solargraph::Pin::Base.new(zero_location, '', 'Foo', merge_comment)
    expect(pin1.try_merge!(pin2)).to eq(true)
    expect(pin1.comments).to eq(merge_comment)
  end

  it "will not merge pins with directive changes" do
    pin1 = Solargraph::Pin::Base.new(zero_location, '', 'Foo', 'A Foo class')
    pin2 = Solargraph::Pin::Base.new(zero_location, '', 'Foo', '@!macro my_macro')
    expect(pin1.nearly?(pin2)).to be(false)
    expect(pin1.try_merge!(pin2)).to be(false)
  end

  it "will not merge pins with different directives" do
    pin1 = Solargraph::Pin::Base.new(zero_location, '', 'Foo', '@!macro my_macro')
    pin2 = Solargraph::Pin::Base.new(zero_location, '', 'Foo', '@!macro other')
    expect(pin1.nearly?(pin2)).to be(false)
    expect(pin1.try_merge!(pin2)).to be(false)
  end

  it "sees tag differences as not near or equal" do
    pin1 = Solargraph::Pin::Base.new(zero_location, '', 'Foo', '@return [Foo]')
    pin2 = Solargraph::Pin::Base.new(zero_location, '', 'Foo', '@return [Bar]')
    expect(pin1.nearly?(pin2)).to be(false)
    expect(pin1 == pin2).to be(false)
  end

  it "sees comment differences as nearly but not equal" do
    pin1 = Solargraph::Pin::Base.new(zero_location, '', 'Foo', 'A Foo class')
    pin2 = Solargraph::Pin::Base.new(zero_location, '', 'Foo', 'A different Foo')
    expect(pin1.nearly?(pin2)).to be(true)
    expect(pin1 == pin2).to be(false)
  end

  it "recognizes deprecated tags" do
    pin = Solargraph::Pin::Base.new(zero_location, '', 'Foo', '@deprecated Use Bar instead.')
    expect(pin).to be_deprecated
  end

  it "turns indented docstring blocks into code blocks" do
    pin = Solargraph::Pin::Base.new(nil, '', 'Foo', %(
Example:

  def meth
    foo = Foo.new
    foo.bar
  end

Hmm.
      ).strip)
    expect(pin.documentation).to include(%(
```
def meth
  foo = Foo.new
  foo.bar
end
```
    ).strip)
  end

  it "does not link documentation for undefined return types" do
    pin = Solargraph::Pin::Base.new(nil, '', 'Foo', '@return [undefined]')
    expect(pin.link_documentation).to be_nil
  end
end
