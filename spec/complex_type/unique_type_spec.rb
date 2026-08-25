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

  describe '#key_type_tag?' do
    it 'matches a single literal key type' do
      type = Solargraph::ComplexType.parse('Hash{"Index" => Float}').first
      expect(type.key_type_tag?('"Index"')).to be(true)
      expect(type.key_type_tag?('"Other"')).to be(false)
    end

    it 'matches every member of a union key type, not just the first' do
      type = Solargraph::ComplexType.parse('Hash{"Index"|"Name" => Float}').first
      expect(type.key_type_tag?('"Index"')).to be(true)
      expect(type.key_type_tag?('"Name"')).to be(true)
      expect(type.key_type_tag?('"Other"')).to be(false)
    end
  end
end
