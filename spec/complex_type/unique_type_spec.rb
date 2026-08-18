# frozen_string_literal: true

describe Solargraph::ComplexType::UniqueType do
  describe '::BOT' do
    it 'is a bot type' do
      expect(described_class::BOT.bot?).to be true
    end

    it 'is rooted' do
      expect(described_class::BOT.rooted?).to be true
    end

    it 'is equal to ComplexType::BOT.first' do
      expect(described_class::BOT).to eq(Solargraph::ComplexType::BOT.first)
    end
  end

  describe '#any?' do
    let(:type) { described_class.parse('String') }

    it 'yields one and only one type, itself' do
      types_encountered = []
      type.any? { |t| types_encountered << t }
      expect(types_encountered).to eq([type])
    end
  end
end
