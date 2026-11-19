# frozen_string_literal: true

describe Solargraph::ComplexType do
  describe '.intern' do
    let(:item) { Solargraph::ComplexType::UniqueType.parse('String') }

    it 'hands two unions over one item the same object, so equal types cost one slot' do
      first = described_class.intern([item])
      second = described_class.intern([item])
      expect(first).to be(second)
    end

    it 'keys on items after a union drops its repeats' do
      expect(described_class.intern([item, item])).to be(described_class.intern([item]))
    end

    it 'keeps unions apart when only a member differs' do
      other = Solargraph::ComplexType::UniqueType.parse('Integer')
      expect(described_class.intern([item])).not_to be(described_class.intern([other]))
    end
  end
end
