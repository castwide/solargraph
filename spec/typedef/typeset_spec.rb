# frozen_string_literal: true

describe Solargraph::Typedef::Typeset do
  describe '.new' do
    it 'accepts multiple types' do
      type1 = Solargraph::Typedef::Type.new(Solargraph::Typedef.tokenize('Array'))
      type2 = Solargraph::Typedef::Type.new(Solargraph::Typedef.tokenize('String'))
      typeset = described_class.new([type1, type2])
      expect(typeset.to_s).to eq('Array | String')
    end

    it 'reduces to unique types' do
      type1 = Solargraph::Typedef::Type.new(Solargraph::Typedef.tokenize('Array'))
      type2 = Solargraph::Typedef::Type.new(Solargraph::Typedef.tokenize('String'))
      type3 = Solargraph::Typedef::Type.new(Solargraph::Typedef.tokenize('Array'))
      typeset = described_class.new([type1, type2, type3])
      expect(typeset.to_s).to eq('Array | String')
    end
  end

  describe '#to_complex_type' do
    it 'converts to complex types' do
      type1 = Solargraph::Typedef::Type.new(Solargraph::Typedef.tokenize('Array'))
      type2 = Solargraph::Typedef::Type.new(Solargraph::Typedef.tokenize('String'))
      typeset = described_class.new([type1, type2])
      complex_type = typeset.to_complex_type
      expect(complex_type).to be_a(Solargraph::ComplexType)
      expect(complex_type.to_s).to eq('Array, String')
    end
  end

  describe '#expand' do
    it 'expands all types' do
      type1 = Solargraph::ComplexType.parse('Array<generic<T>>').to_typedef_typeset
      type2 = Solargraph::ComplexType.parse('Set<generic<T>>').to_typedef_typeset
      typeset = described_class.new([type1, type2])
      named_values = { 'generic<T>' => 'String' }
      expanded = typeset.expand(named_values)
      expect(expanded.to_s).to eq('Array[String] | Set[String]')
    end
  end

  describe '#nullable?' do
    it 'returns true with a nil return type' do
      complex_type = Solargraph::ComplexType.parse('String, nil')
      typeset = complex_type.to_typedef_typeset
      expect(typeset).to be_nullable
    end

    it 'returns false without a nil return type' do
      complex_type = Solargraph::ComplexType.parse('String')
      typeset = complex_type.to_typedef_typeset
      expect(typeset).not_to be_nullable
    end
  end

  # Although these tests are for a ComplexType method, they're collected here
  # because they're specific to the Typedef library. They'll eventually get
  # deprecated along with the ComplexType library itself.
  describe 'ComplexType#to_typedef_typeset' do
    it 'handles complex types with hashes' do
      complex_type = Solargraph::ComplexType.parse('Hash{String => Integer}')
      expect(complex_type.to_typedef_typeset.to_s).to eq('Hash[String, Integer]')
    end

    it 'handles complex types with hashes and non-hash parameters' do
      complex_type = Solargraph::ComplexType.parse('Hash<String, Integer>')
      expect(complex_type.to_typedef_typeset.to_s).to eq('Hash[String, Integer]')
    end

    it 'handles complex types with inline hashes' do
      complex_type = Solargraph::ComplexType.parse('Array<undefined>, Hash{String => undefined}, String, Integer')
      expect(complex_type.to_typedef_typeset.to_s).to eq('Array[undefined] | Hash[String, undefined] | String | Integer')
    end

    it 'handles complex types with inline hashes and non-hash parameters' do
      complex_type = Solargraph::ComplexType.parse('Array<undefined>, Hash<String, undefined>, String, Integer')
      expect(complex_type.to_typedef_typeset.to_s).to eq('Array[undefined] | Hash[String, undefined] | String | Integer')
    end
  end
end
