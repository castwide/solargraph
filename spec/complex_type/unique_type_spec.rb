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

  # UniqueType#narrow_with duplicates ComplexType#narrow_with (see
  # spec/complex_type/narrow_with_spec.rb) but is reachable on its
  # own: BaseVariable#adjust_type calls #exclude before #narrow_with,
  # and #exclude returns self - a bare UniqueType, unwrapped - when
  # there's no exclusion type to apply.
  describe '#narrow_with' do
    let(:api_map) { Solargraph::ApiMap.new }

    it 'returns self unchanged when narrowing_type is nil' do
      type = described_class.parse('String')
      expect(type.narrow_with(nil, api_map)).to be(type)
    end

    it 'returns the narrowing type unchanged when self is undefined' do
      narrowing = Solargraph::ComplexType.parse('String')
      expect(described_class::UNDEFINED.narrow_with(narrowing, api_map)).to be(narrowing)
    end

    it 'keeps the original type when it already conforms to the narrowing type' do
      type = described_class.parse('String')
      narrowing = Solargraph::ComplexType.parse('Object')
      narrowed = type.narrow_with(narrowing, api_map)
      expect(narrowed.tag).to eq('String')
    end

    it 'uses the narrowing type when it is the more specific of the pair' do
      type = described_class.parse('Object')
      narrowing = Solargraph::ComplexType.parse('String')
      narrowed = type.narrow_with(narrowing, api_map)
      expect(narrowed.tag).to eq('String')
    end

    it 'falls back to undefined when neither side conforms and neither is a mix-in' do
      type = described_class.parse('String')
      narrowing = Solargraph::ComplexType.parse('Integer')
      narrowed = type.narrow_with(narrowing, api_map)
      expect(narrowed.tag).to eq('undefined')
    end

    context 'when narrowing a class with an unrelated mix-in' do
      let(:source) do
        Solargraph::Source.load_string(%(
          module M; end
          class T; end
        ))
      end

      before { api_map.map source }

      it 'combines both facts into an Intersection instead of dropping the pair' do
        type = described_class.parse('T')
        narrowing = Solargraph::ComplexType.parse('M')
        narrowed = type.narrow_with(narrowing, api_map)
        expect(narrowed.first).to be_a(described_class::Intersection)
        expect(narrowed.tag).to eq('T & M')
      end
    end
  end

  describe '#mixin_pairing?' do
    let(:api_map) { Solargraph::ApiMap.new }
    let(:source) do
      Solargraph::Source.load_string(%(
        module M; end
        class C; end
      ))
    end

    before { api_map.map source }

    it 'is true when the declared side is a module' do
      declared = described_class.parse('M')
      candidate = described_class.parse('C')
      expect(declared.send(:mixin_pairing?, api_map, declared, candidate)).to be(true)
    end

    it 'is true when the candidate side is a module' do
      declared = described_class.parse('C')
      candidate = described_class.parse('M')
      expect(declared.send(:mixin_pairing?, api_map, declared, candidate)).to be(true)
    end

    it 'is false when neither side is a module' do
      declared = described_class.parse('C')
      candidate = described_class.parse('C')
      expect(declared.send(:mixin_pairing?, api_map, declared, candidate)).to be(false)
    end
  end

  describe '#namespace_kind' do
    let(:api_map) { Solargraph::ApiMap.new }
    let(:source) do
      Solargraph::Source.load_string(%(
        module M; end
        class C; end
      ))
    end

    before { api_map.map source }

    it 'identifies a class' do
      type = described_class.parse('C')
      expect(type.send(:namespace_kind, api_map, type)).to be(:class)
    end

    it 'identifies a module' do
      type = described_class.parse('M')
      expect(type.send(:namespace_kind, api_map, type)).to be(:module)
    end

    it 'returns nil when the namespace has no pin' do
      type = described_class.parse('NoSuchNamespace')
      expect(type.send(:namespace_kind, api_map, type)).to be_nil
    end
  end
end
