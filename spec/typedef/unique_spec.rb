# frozen_string_literal: true

describe Solargraph::Typedef::Unique do
  describe '#from' do
    it 'updates paths' do
    end
  end

  describe '#expand' do
    it 'resolves simple named tokens to paths' do
      named_values = { 'foo' => 'String' }
      type = described_class.new('foo')
      resolved = type.expand(named_values)
      expect(resolved.to_s).to eq('String')
    end

    it 'resolves simple named tokens to rooted paths' do
      named_values = { 'foo' => '::String' }
      type = described_class.new('foo')
      resolved = type.expand(named_values)
      expect(resolved.to_s).to eq('String')
      expect(resolved).to be_resolved
    end

    it 'returns unresolved types' do
      named_values = { 'foo' => 'String' }
      type = described_class.new('bar')
      unresolved = type.expand(named_values)
      expect(unresolved.to_s).to eq('bar')
      expect(unresolved).not_to be_resolved
    end
  end

  describe '#any_generic?' do
    it 'is true if any parameter is generic' do
      type = Solargraph::ComplexType.parse('Array<generic<T>>').to_typedef_types.first
      expect(type).to be_any_generic
    end

    it 'is false if no parameters are generic' do
      type = Solargraph::ComplexType.parse('Array<String>').to_typedef_types.first
      expect(type).not_to be_any_generic
    end
  end

  describe '#all_generic?' do
    it 'coincides with #any_generic?, since a Unique is a single member' do
      generic_type = Solargraph::ComplexType.parse('Array<generic<T>>').to_typedef_types.first
      plain_type = Solargraph::ComplexType.parse('Array<String>').to_typedef_types.first
      expect(generic_type.all_generic?).to eq(generic_type.any_generic?)
      expect(plain_type.all_generic?).to eq(plain_type.any_generic?)
    end
  end
end
