# frozen_string_literal: true

describe Solargraph::ComplexType::UniqueType do
  describe '#any?' do
    let(:type) { described_class.parse('String') }

    it 'yields one and only one type, itself' do
      types_encountered = []
      type.any? { |t| types_encountered << t }
      expect(types_encountered).to eq([type])
    end
  end

  describe '#exclude' do
    let(:api_map) { Solargraph::ApiMap.new }

    let(:source) do
      Solargraph::Source.load_string(%(
        class Sup; end
        class Sub < Sup; end
      ))
    end

    before { api_map.map source }

    it 'returns self when exclude_types is nil' do
      type = described_class.parse('Sub')
      expect(type.exclude(nil, api_map)).to be(type)
    end

    it 'falls back to UNDEFINED when the receiver conforms to the excluded type' do
      type = described_class.parse('Sub')
      result = type.exclude(Solargraph::ComplexType.parse('Sup'), api_map)
      expect(result.tags).to eq('undefined')
    end

    it 'keeps the receiver when it does not conform to the excluded type' do
      type = described_class.parse('Sup')
      result = type.exclude(Solargraph::ComplexType.parse('Sub'), api_map)
      expect(result.tags).to eq('Sup')
    end
  end
end
