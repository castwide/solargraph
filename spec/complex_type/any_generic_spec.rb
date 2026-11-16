# frozen_string_literal: true

describe Solargraph::ComplexType do
  describe '#any_generic?' do
    it 'is true when a later member of a union mentions a type parameter' do
      expect(described_class.parse('String', 'Array<generic<T>>')).to be_any_generic
    end

    it 'is false when no member does' do
      expect(described_class.parse('String', 'Array<Integer>')).not_to be_any_generic
    end

    it 'answers for a single type asked directly' do
      expect(described_class.parse('generic<T>').items.first).to be_any_generic
    end
  end
end
