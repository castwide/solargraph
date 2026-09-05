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

  describe '#simplify_literals' do
    it 'leaves a nil literal as nil, not NilClass' do
      type = described_class.parse('nil')
      expect(type.simplify_literals.tag).to eq('nil')
    end
  end
end
