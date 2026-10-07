# frozen_string_literal: true

describe Solargraph::ComplexType::UniqueType do
  describe '::BOT' do
    it 'is a bot type' do
      expect(described_class::BOT.bot?).to be true
    end

    it 'is rooted' do
      expect(described_class::BOT.rooted?).to be true
    end

    it 'is equal to ComplexType::BOT.first' do
      expect(described_class::BOT).to eq(Solargraph::ComplexType::BOT.first)
    end
  end

  describe '#any?' do
    let(:type) { described_class.parse('String') }

    it 'yields one and only one type, itself' do
      types_encountered = []
      type.any? { |t| types_encountered << t }
      expect(types_encountered).to eq([type])
    end
  end

  describe '#exclude' do
    let(:api_map) { Solargraph::ApiMap.new }

    let(:source) do
      Solargraph::Source.load_string(%(
        module Mixin; end
        class Sup; end
        class Sub < Sup; end
        class Includer; include Mixin; end
        class ViaSuperclass < Includer; end
      ))
    end

    before { api_map.map source }

    it 'returns self when exclude_types is nil' do
      type = described_class.parse('Sub')
      expect(type.exclude(nil, api_map)).to be(type)
    end

    it 'tags the result bot when the receiver conforms to the excluded type' do
      type = described_class.parse('Sub')
      result = type.exclude(Solargraph::ComplexType.parse('Sup'), api_map)
      expect(result.tags).to eq('bot')
    end

    it 'keeps the receiver when it does not conform to the excluded type' do
      type = described_class.parse('Sup')
      result = type.exclude(Solargraph::ComplexType.parse('Sub'), api_map)
      expect(result.tags).to eq('Sup')
    end

    it 'excludes a class that includes the excluded module' do
      type = described_class.parse('Includer')
      result = type.exclude(Solargraph::ComplexType.parse('Mixin'), api_map)
      expect(result.tags).to eq('bot')
    end

    it 'excludes a class whose superclass includes the excluded module' do
      pending 'https://github.com/castwide/solargraph/pull/1384'
      type = described_class.parse('ViaSuperclass')
      result = type.exclude(Solargraph::ComplexType.parse('Mixin'), api_map)
      expect(result.tags).to eq('bot')
    end
  end
end
