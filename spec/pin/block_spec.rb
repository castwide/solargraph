# frozen_string_literal: true

describe Solargraph::Pin::Block do
  let(:foo) { instance_double(Solargraph::Pin::Parameter, name: 'foo') }
  let(:bar) { instance_double(Solargraph::Pin::Parameter, name: 'bar') }
  let(:block) { instance_double(Solargraph::Pin::Parameter, name: 'block') }

  it 'strips prefixes from parameter names' do
    pin = described_class.new(args: [foo, bar, block])
    expect(pin.parameter_names).to eq(%w[foo bar block])
  end

  it 'types parameters in files the ApiMap has no source map for' do
    gem_map = Solargraph::SourceMap.load_string(%(
      'a'.each_char do |char|
        char
      end
    ), 'gem.rb')
    api_map = Solargraph::ApiMap.new(pins: gem_map.pins)
    pin = gem_map.pins.find { |p| p.is_a?(described_class) }
    expect(pin.typify_parameters(api_map).map(&:tag)).to eq(['String'])
  end
end
