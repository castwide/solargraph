describe Solargraph::Source::Chain do
  it "gets empty definitions for undefined links" do
    chain = described_class.new([Solargraph::Source::Chain::Link.new])
    expect(chain.define(nil, nil, nil)).to be_empty
  end

  it "infers undefined types for undefined links" do
    chain = described_class.new([Solargraph::Source::Chain::Link.new])
    expect(chain.infer(nil, nil, nil)).to be_undefined
  end

  it "calls itself undefined if any of its links are undefined" do
    chain = described_class.new([Solargraph::Source::Chain::Link.new])
    expect(chain).to be_undefined
  end

  it "returns undefined bases for single links" do
    chain = described_class.new([Solargraph::Source::Chain::Link.new])
    expect(chain.base).to be_undefined
  end

  it "defines constants from core classes" do
    api_map = Solargraph::ApiMap.new
    chain = described_class.new([Solargraph::Source::Chain::Constant.new('String')])
    pins = chain.define(api_map, Solargraph::Context::ROOT, [])
    expect(pins.first.kind).to eq(Solargraph::Pin::NAMESPACE)
    expect(pins.first.path).to eq('String')
  end

  it "infers types from core classes" do
    api_map = Solargraph::ApiMap.new
    chain = described_class.new([Solargraph::Source::Chain::Constant.new('String')])
    type = chain.infer(api_map, Solargraph::Context::ROOT, [])
    expect(type.namespace).to eq('String')
    expect(type.scope).to eq(:class)
  end

  it "infers types from core methods" do
    api_map = Solargraph::ApiMap.new
    chain = described_class.new([Solargraph::Source::Chain::Constant.new('String'), Solargraph::Source::Chain::Call.new('new')])
    type = chain.infer(api_map, Solargraph::Context::ROOT, [])
    expect(type.namespace).to eq('String')
    expect(type.scope).to eq(:instance)
  end
end
