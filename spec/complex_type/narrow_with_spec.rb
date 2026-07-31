# frozen_string_literal: true

# ComplexType#narrow_with is flow-sensitive type narrowing (e.g.
# refining a declared type using a type learned from an `is_a?`
# guard) - see spec/parser/flow_sensitive_typing_spec.rb for
# end-to-end coverage through real source. These specs exercise the
# narrowing logic directly.
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
      expect(narrowed.first).to be_a(Solargraph::ComplexType::UniqueType::Intersection)
      expect(narrowed.tag).to eq('T & M')
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
end
