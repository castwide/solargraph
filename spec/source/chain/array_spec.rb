describe Solargraph::Source::Chain::Array do
  it "resolves an instance of an array" do
    literal = described_class.new([], nil)
    pin = literal.resolve(nil, nil, nil).first
    expect(pin.return_type.tag).to eq('Array')
  end
end
