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

  describe '#eql?' do
    it 'equals itself when its name cannot be rooted' do
      undefined = described_class::UNDEFINED
      expect(undefined.eql?(undefined)).to be(true)
    end

    it 'ignores the rooted flag when the name cannot be rooted' do
      rooted = described_class.new('undefined', rooted: true)
      expect([rooted == described_class::UNDEFINED, rooted.hash == described_class::UNDEFINED.hash]).to eq([true, true])
    end
  end
end
