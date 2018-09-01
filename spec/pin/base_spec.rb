describe Solargraph::Pin::Base do
  let(:zero_location) { Solargraph::Source::Location.new('test.rb', Solargraph::Range.from_to(0, 0, 0, 0)) }
  let(:one_location) { Solargraph::Source::Location.new('test.rb', Solargraph::Range.from_to(0, 0, 1, 0)) }

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
end
