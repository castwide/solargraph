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

  describe '#qualify' do
    it 'keeps a nil literal as nil, not ::NilClass' do
      type = described_class.parse('nil')
      expect(type.qualify(Solargraph::ApiMap.new).rooted_tags).to eq('nil')
    end

    it 'keeps a symbol literal as :foo, not ::Symbol' do
      type = described_class.parse(':foo')
      expect(type.qualify(Solargraph::ApiMap.new).rooted_tags).to eq(':foo')
    end

    it 'keeps an integer literal as 1, not ::Integer' do
      type = described_class.parse('1')
      expect(type.qualify(Solargraph::ApiMap.new).rooted_tags).to eq('1')
    end
  end

  describe '#simplify_literals' do
    it 'leaves a nil literal as nil, not NilClass' do
      type = described_class.parse('nil')
      expect(type.simplify_literals.tag).to eq('nil')
    end
  end
end
