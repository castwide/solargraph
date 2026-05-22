# frozen_string_literal: true

describe Solargraph::Typedef::Type do
  describe '#from' do
    it 'updates paths' do
    end
  end

  describe '.from_complex_type' do
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
end
