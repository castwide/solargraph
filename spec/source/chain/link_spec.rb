describe Solargraph::Source::Chain::Link do
  it "is undefined by default" do
    link = described_class.new
    expect(link).to be_undefined
  end

  it "is not a constant by default" do
    link = described_class.new
    expect(link).not_to be_constant
  end

  it "resolves empty arrays by default" do
    link = described_class.new
    expect(link.resolve(nil, nil, nil)).to be_empty
  end

  it "recognizes equivalent links" do
    l1 = described_class.new('foo')
    l2 = described_class.new('foo')
    expect(l1).to eq(l2)
  end

  it "recognizes inequivalent links" do
    l1 = described_class.new('foo')
    l2 = described_class.new('bar')
    expect(l1).not_to eq(l2)
  end
end
