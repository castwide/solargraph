# frozen_string_literal: true

describe Solargraph::ComplexType do
  describe '#any_duck_type?' do
    it 'is true when a later member of a union is a duck type' do
      expect(described_class.parse('String', '#to_s')).to be_any_duck_type
    end

    it 'is false when no member is' do
      expect(described_class.parse('String', 'Integer')).not_to be_any_duck_type
    end

    it 'answers for a single type asked directly' do
      expect(described_class.parse('#to_s').items.first).to be_any_duck_type
    end
  end
end
