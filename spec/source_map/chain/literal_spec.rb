describe Solargraph::SourceMap::Chain::Literal do
  it "resolves an instance of a literal" do
    literal = described_class.new('String')
    pin = literal.resolve(nil, nil, nil).first
    expect(pin.return_complex_type.tag).to eq('String')
  end
end
