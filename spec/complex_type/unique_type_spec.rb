# frozen_string_literal: true

describe Solargraph::ComplexType::UniqueType do
  describe '#items' do
    let(:type) { described_class.parse('String') }

    it 'holds one and only one type, itself' do
      expect(type.items).to eq([type])
    end
  end
end
