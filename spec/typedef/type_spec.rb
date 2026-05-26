# frozen_string_literal: true

describe Solargraph::Typedef::Type do
  describe '#from' do
    it 'updates paths' do
    end
  end

  describe '.from_complex_type' do
    it 'converts core pin return types' do
      api_map = Solargraph::ApiMap.new
      api_map.pins.each { |pin| Solargraph::Typedef::Type.from_complex_type(pin.return_type) }
    end

    context 'with an unrooted path' do
      let(:complex_type) { Solargraph::ComplexType.parse('Foo') }
      let(:types) { described_class.from_complex_type(complex_type) }

      it 'converts to one type' do
        expect(types).to be_one
      end

      it 'converts to a path' do
        expect(types.first.to_s).to eq('Foo')
        expect(types.first.base).to be_a(Solargraph::Typedef::Path)
      end

      it 'does not resolve' do
        expect(types.first).not_to be_resolved
      end
    end

    context 'with a rooted path' do
      let(:complex_type) { Solargraph::ComplexType.parse('::Foo') }
      let(:types) { described_class.from_complex_type(complex_type) }

      it 'converts to one type' do
        expect(types).to be_one
      end

      it 'converts to a path' do
        expect(types.first.to_s).to eq('Foo')
        expect(types.first.base).to be_a(Solargraph::Typedef::Path)
      end

      it 'is rooted' do
        expect(types.first.base).to be_rooted
      end

      it 'resolves' do
        expect(types.first).to be_resolved
      end
    end

    context 'with a parameterized type' do
      let(:complex_type) { Solargraph::ComplexType.parse('Array<String>') }
      let(:types) { described_class.from_complex_type(complex_type) }

      it 'converts to paths' do
        expect(types.first.to_s).to eq('Array[String]')
      end
    end
  end

  describe '#expand' do
    it 'resolves simple named tokens to paths' do
      named_values = { "foo" => "String" }
      type = described_class.new('foo')
      resolved = type.expand(named_values)
      expect(resolved.to_s).to eq('String')
    end

    it 'resolves simple named tokens to rooted paths' do
      named_values = { "foo" => "::String" }
      type = described_class.new('foo')
      resolved = type.expand(named_values)
      expect(resolved.to_s).to eq('String')
      expect(resolved).to be_resolved
    end

    it 'returns unresolved types' do
      named_values = { "foo" => "String" }
      type = described_class.new('bar')
      unresolved = type.expand(named_values)
      expect(unresolved.to_s).to eq('bar')
      expect(unresolved).not_to be_resolved
    end
  end

  describe '#generic?' do
    it 'is true if any parameter is generic' do
      type = Solargraph::ComplexType.parse('Array<generic<T>>').to_typedef_types.first
      expect(type).to be_generic
    end

    it 'is false if no parameters are generic' do
      type = Solargraph::ComplexType.parse('Array<String>').to_typedef_types.first
      expect(type).not_to be_generic
    end
  end
end
