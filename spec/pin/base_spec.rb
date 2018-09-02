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
    merge_comment = '@!macro my_macro'
    pin2 = Solargraph::Pin::Base.new(zero_location, '', 'Foo', merge_comment)
    expect(pin1.nearly?(pin2)).to be(false)
  end

  it "recognizes deprecated tags" do
    pin = Solargraph::Pin::Base.new(zero_location, '', 'Foo', '@deprecated Use Bar instead.')
    expect(pin).to be_deprecated
  end
end
