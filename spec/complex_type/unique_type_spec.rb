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

  describe '.intern' do
    it 'hands two parses of one type the same object, so equal types cost one slot' do
      first = described_class.parse('Array', '<String>')
      second = described_class.parse('Array', '<String>')
      expect(first).to be(second)
    end

    it 'hands back the receiver when recreate is asked for no change' do
      type = described_class.parse('Array', '<String>')
      expect(type.recreate).to be(type)
    end

    it 'hands two recreates that rebuild one type the same object' do
      type = described_class.parse('Hash', '{Symbol => Array<String>}')
      first = type.recreate(new_name: 'Array')
      second = type.recreate(new_name: 'Array')
      expect(first).to be(second)
    end

    it 'hands back a seeded constant rather than an equal new type' do
      expect(described_class::UNDEFINED.recreate).to be(described_class::UNDEFINED)
    end

    it 'keys on parameters after an implicit union drops its repeats' do
      expect(described_class.parse('Array', '<String, String>')).to be(described_class.parse('Array', '<String>'))
    end

    it 'keeps types apart when only a parameter differs' do
      expect(described_class.parse('Array', '<String>')).not_to be(described_class.parse('Array', '<Integer>'))
    end

    it 'keeps a rooted type apart from its unrooted spelling' do
      expect(described_class.parse('::Array')).not_to be(described_class.parse('Array'))
    end
  end

  describe '#exclude' do
    let(:api_map) { Solargraph::ApiMap.new }

    it 'returns the receiver untouched when there is nothing to exclude' do
      type = described_class.parse('String')
      expect(type.exclude(nil, api_map)).to be(type)
    end

    it 'falls back to undefined once excluding leaves nothing behind' do
      type = described_class.parse('String')
      result = type.exclude(Solargraph::ComplexType.parse('String'), api_map)
      expect(result.tag).to eq('undefined')
    end
  end

  describe '#intersect_with' do
    let(:api_map) { Solargraph::ApiMap.new }

    it 'returns the receiver untouched when there is nothing to intersect' do
      type = described_class.parse('String')
      expect(type.intersect_with(nil, api_map)).to be(type)
    end

    it 'keeps the type that conforms when both sides name it' do
      type = described_class.parse('String')
      result = type.intersect_with(Solargraph::ComplexType.parse('String'), api_map)
      expect(result.tag).to eq('String')
    end

    it 'falls back to undefined when neither side conforms to the other' do
      type = described_class.parse('String')
      result = type.intersect_with(Solargraph::ComplexType.parse('Integer'), api_map)
      expect(result.tag).to eq('undefined')
    end
  end
end
