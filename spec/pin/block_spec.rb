describe Solargraph::Pin::Block do
  let(:foo) { instance_double(Solargraph::Pin::Parameter, name: 'foo') }
  let(:bar) { instance_double(Solargraph::Pin::Parameter, name: 'bar') }
  let(:block) { instance_double(Solargraph::Pin::Parameter, name: 'block') }

  it 'strips prefixes from parameter names' do
    pin = Solargraph::Pin::Block.new(args: [foo, bar, block])
    expect(pin.parameter_names).to eq(['foo', 'bar', 'block'])
  end
end
