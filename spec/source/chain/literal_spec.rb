describe Solargraph::Source::Chain::Literal do
  it "resolves an instance of a literal" do
    literal = described_class.new('String', nil)
    api_map = Solargraph::ApiMap.new
    pin = literal.resolve(api_map, nil, nil).first
    expect(pin.return_type.tag).to eq('String')
  end
end
