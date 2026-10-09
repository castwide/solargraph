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
end
