# frozen_string_literal: true

describe Solargraph::ComplexType do
  describe '#order_nil_last' do
    it 'moves nil to the end and keeps the other members in order' do
      expect(described_class.parse('nil', 'String', 'Integer').order_nil_last.tags).to eq('String, Integer, nil')
    end

    it 'leaves a single type as it is' do
      type = described_class.parse('nil').items.first
      expect(type.order_nil_last).to be(type)
    end
  end
end
