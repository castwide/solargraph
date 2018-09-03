describe Solargraph::Diagnostics::Base do
  it "returns empty diagnostics" do
    reporter = Solargraph::Diagnostics::Base.new
    expect(reporter.diagnose(nil, nil)).to be_empty
  end
end
