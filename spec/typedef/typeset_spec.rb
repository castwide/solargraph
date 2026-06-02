# frozen_string_literal: true

describe Solargraph::Typedef::Typeset do
  it 'accepts multiple types' do
    type1 = Solargraph::Typedef::Type.new(Solargraph::Typedef.tokenize('Array'))
    type2 = Solargraph::Typedef::Type.new(Solargraph::Typedef.tokenize('String'))
    typeset = described_class.new([type1, type2])
    expect(typeset.to_s).to eq('Array | String')
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

  describe '.from_complex_type' do
    it 'converts from complex types' do
      complex_type = Solargraph::ComplexType.parse('Array', 'String')
      typeset = described_class.from_complex_type(complex_type)
      expect(typeset.to_s).to eq('Array | String')
    end

    it 'converts from complex types with simple parameters' do
      complex_type = Solargraph::ComplexType.parse('Array<String>')
      typeset = described_class.from_complex_type(complex_type)
      expect(typeset.to_s).to eq('Array[String]')
    end

    it 'converts from complex types with complex parameters' do
      complex_type = Solargraph::ComplexType.parse('Array<String, Integer>')
      typeset = described_class.from_complex_type(complex_type)
      expect(typeset.to_s).to eq('Array[String | Integer]')
    end

    it 'converts from complex types with hash parameters' do
      complex_type = Solargraph::ComplexType.parse('Hash{String => Array<undefined>, Hash{String => undefined}, String, Integer}')
      typeset = described_class.from_complex_type(complex_type)
      expect(typeset.to_s).to eq('Hash[String, Array[undefined] | Hash[String, undefined] | String | Integer]')
    end

    it 'converts back from complex types with hash parameters' do
      complex_type = Solargraph::ComplexType.parse('Hash{String => Array<undefined>, Hash{String => undefined}, String, Integer}')
      typeset = described_class.from_complex_type(complex_type)
      expect(typeset.to_s).to eq('Hash[String, Array[undefined] | Hash[String, undefined] | String | Integer]')
      # The format from #to_complex_type is slightly different but functionally equivalent
      expect(typeset.to_complex_type.to_s).to eq('Hash{String => Array, Hash{String => undefined}, String, Integer}')
    end

    it 'converts from complex types with tuple parameters' do
      complex_type = Solargraph::ComplexType.parse('Array(String, Integer)')
      typeset = described_class.from_complex_type(complex_type)
      expect(typeset.to_s).to eq('Array(String, Integer)')
    end
  end

  describe '#expand' do
    it 'expands all types' do
      type1 = Solargraph::Typedef::Type.from_complex_type(Solargraph::ComplexType.parse('Array<generic<T>>')).first
      type2 = Solargraph::Typedef::Type.from_complex_type(Solargraph::ComplexType.parse('Set<generic<T>>')).first
      typeset = described_class.new([type1, type2])
      named_values = { 'generic<T>' => 'String' }
      expanded = typeset.expand(named_values)
      expect(expanded.to_s).to eq('Array[String] | Set[String]')
    end
  end
end
