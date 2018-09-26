describe Solargraph::Position do
  it "normalizes arrays into positions" do
    pos = Solargraph::Position.normalize([0, 1])
    expect(pos).to be_a(Solargraph::Position)
    expect(pos.line).to eq(0)
    expect(pos.column).to eq(1)
  end

  it "returns original positions when normalizing" do
    orig = Solargraph::Position.new(0, 1)
    norm = Solargraph::Position.normalize(orig)
    expect(orig).to be(norm)
  end

  it "raises an error for objects that cannot be normalized" do
    expect {
      Solargraph::Position.normalize('0, 1')
    }.to raise_error(ArgumentError)
  end
end
