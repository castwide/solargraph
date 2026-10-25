# frozen_string_literal: true

describe Solargraph::ComplexType::UniqueType do
  describe '#items' do
    let(:type) { described_class.parse('String') }

    it 'holds one and only one type, itself' do
      expect(type.items).to eq([type])
    end
  end

  describe '#nullable?' do
    it 'is true for nil' do
      expect(described_class::NIL.nullable?).to be(true)
    end

    it 'is false for a named type' do
      expect(described_class.parse('String').nullable?).to be(false)
    end
  end

  # BaseVariable#adjust_type reaches this on a bare UniqueType, since
  # #exclude returns self when there is nothing to exclude.
  describe '#intersect_with' do
    let(:api_map) { Solargraph::ApiMap.new }

    it 'keeps itself when it conforms to a member of the other type' do
      type = described_class.parse('::Integer')
      expect(type.intersect_with(Solargraph::ComplexType.parse('::Numeric', '::String'), api_map).tags)
        .to eq('Integer')
    end

    it 'takes the more specific member of the other type' do
      type = described_class.parse('::Numeric')
      expect(type.intersect_with(Solargraph::ComplexType.parse('::Integer'), api_map).tags).to eq('Integer')
    end

    it 'is undefined when nothing lines up' do
      type = described_class.parse('::Integer')
      expect(type.intersect_with(Solargraph::ComplexType.parse('::String'), api_map).tags).to eq('undefined')
    end
  end
end
