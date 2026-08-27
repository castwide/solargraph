# frozen_string_literal: true

describe Solargraph::ComplexType do
  let(:api_map) do
    Solargraph::ApiMap.new
  end

  describe '#intersect_with' do
    it 'accepts a bare UniqueType (not wrapped in a ComplexType) as intersection_type' do
      receiver = described_class.parse('Integer')
      # A bare UniqueType, as intersect_with's own signature declares
      # it may receive, rather than a ComplexType wrapping one.
      bare_unique_type = described_class.parse('String').to_a.first
      expect(bare_unique_type).to be_a(Solargraph::ComplexType::UniqueType)

      result = receiver.intersect_with(bare_unique_type, api_map)

      expect(result).to be_undefined
    end
  end
end
