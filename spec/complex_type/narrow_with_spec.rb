# frozen_string_literal: true

# ComplexType#narrow_with is flow-sensitive type narrowing (e.g.
# from an `is_a?` guard) - see
# spec/parser/flow_sensitive_typing_spec.rb for end-to-end coverage.
describe Solargraph::ComplexType do
  let(:api_map) { Solargraph::ApiMap.new }

  context 'when narrowing a class with an unrelated mix-in' do
    let(:source) do
      Solargraph::Source.load_string(%(
        module M; end
        class T; end
      ))
    end

    before { api_map.map source }

    it 'builds an intersection rather than discarding both facts' do
      declared = described_class.parse('T')
      learned = described_class.parse('M')
      narrowed = declared.narrow_with(learned, api_map)
      expect(narrowed.items.first).to be_a(Solargraph::ComplexType::UniqueType::Intersection)
      expect(narrowed.tags).to eq('T & M')
    end

    it 'lets the narrowed intersection satisfy either original fact' do
      declared = described_class.parse('T')
      learned = described_class.parse('M')
      narrowed = declared.narrow_with(learned, api_map)
      expect(narrowed.conforms_to?(api_map, described_class.parse('T'), :method_call)).to be(true)
      expect(narrowed.conforms_to?(api_map, described_class.parse('M'), :method_call)).to be(true)
    end
  end

  context 'when the mix-in is already known to be included' do
    let(:source) do
      Solargraph::Source.load_string(%(
        module M; end
        class T
          include M
        end
      ))
    end

    before { api_map.map source }

    it 'simplifies to the already-more-specific type instead of building a redundant intersection' do
      declared = described_class.parse('T')
      learned = described_class.parse('M')
      narrowed = declared.narrow_with(learned, api_map)
      expect(narrowed.tag).to eq('T')
    end
  end

  context 'when narrowing a union whose members relate to the mix-in differently' do
    let(:source) do
      Solargraph::Source.load_string(%(
        module M; end
        class A; end
        class B; end
        class A_with_M < A; include M; end
        class B_with_M < B; include M; end
      ))
    end

    let(:declared) { described_class.parse('A, B_with_M').qualify(api_map, '') }
    let(:guard) { described_class.parse('M').qualify(api_map, '') }

    before { api_map.map source }

    it 'intersects only the member the guard neither implies nor is implied by' do
      expect(declared.narrow_with(guard, api_map).rooted_tags).to eq('::A & ::M, ::B_with_M')
    end

    it 'keeps admitting a subclass of A that mixes in M' do
      narrowed = declared.narrow_with(guard, api_map)
      inhabitant = described_class.parse('A_with_M').qualify(api_map, '')
      expect(inhabitant.conforms_to?(api_map, narrowed, :assignment)).to be(true)
    end
  end

  context 'when narrowing a class with a duck type' do
    let(:source) do
      Solargraph::Source.load_string(%(
        class T; end
      ))
    end

    before { api_map.map source }

    it 'builds an intersection rather than discarding the class' do
      pending 'https://github.com/castwide/solargraph/pull/1297'
      declared = described_class.parse('T')
      learned = described_class.parse('#bar')
      narrowed = declared.narrow_with(learned, api_map)
      expect(narrowed.tag).to eq('T & #bar')
    end
  end
end
