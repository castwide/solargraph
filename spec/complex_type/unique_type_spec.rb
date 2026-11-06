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

  # ComplexType#intersect_with is a sibling copy of this one, tested in
  # complex_type_spec.rb. Both are covered so the two cannot drift apart.
  describe '#intersect_with' do
    let(:api_map) do
      api_map = Solargraph::ApiMap.new
      api_map.map Solargraph::Source.load_string(%(
        module M; end
        class A; end
        class A_with_M < A; include M; end
      ), 'test.rb')
      api_map
    end

    let(:guard) { Solargraph::ComplexType.parse('M').qualify(api_map, '') }

    it 'keeps the guard when neither type implies the other and one is a module' do
      declared = described_class.parse('A').qualify(api_map, '')
      expect(declared.intersect_with(guard, api_map).rooted_tags).to eq('::M')
    end

    it 'keeps the narrower type when the declared type already implies the guard' do
      declared = described_class.parse('A_with_M').qualify(api_map, '')
      expect(declared.intersect_with(guard, api_map).rooted_tags).to eq('::A_with_M')
    end

    it 'still admits a value satisfying both the declared type and the guard' do
      declared = described_class.parse('A').qualify(api_map, '')
      inhabitant = Solargraph::ComplexType.parse('A_with_M').qualify(api_map, '')
      narrowed = declared.intersect_with(guard, api_map)
      expect(inhabitant.conforms_to?(api_map, narrowed, :assignment)).to be(true)
    end
  end
end
