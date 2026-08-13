# frozen_string_literal: true

describe Solargraph::ComplexType::UniqueType do
  describe '::BOT' do
    it 'is a bot type' do
      expect(described_class::BOT.bot?).to be true
    end

    it 'is rooted, unlike ::UNDEFINED' do
      expect(described_class::BOT.rooted?).to be true
    end

    it 'is equal to ComplexType::BOT.first' do
      # rooted: true is load-bearing here - #bot?/#tag/#to_s all
      # match regardless of #rooted, but #== (via Equality's
      # equality_fields) also compares the raw @rooted ivar, so a
      # rooted: false construction would silently fail this equality
      # despite looking identical everywhere else.
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
