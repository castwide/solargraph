# frozen_string_literal: true

describe Solargraph::Typedef::Typeset do
  it 'accepts multiple types' do
    type1 = Solargraph::Typedef::Type.new(Solargraph::Typedef.tokenize('Array'))
    type2 = Solargraph::Typedef::Type.new(Solargraph::Typedef.tokenize('String'))
    typeset = described_class.new([type1, type2])
    expect(typeset.to_s).to eq('Array, String')
  end

  it 'converts to complex types' do
    type1 = Solargraph::Typedef::Type.new(Solargraph::Typedef.tokenize('Array'))
    type2 = Solargraph::Typedef::Type.new(Solargraph::Typedef.tokenize('String'))
    typeset = described_class.new([type1, type2])
    complex_type = typeset.to_complex_type
    expect(complex_type).to be_a(Solargraph::ComplexType)
    expect(complex_type.to_s).to eq('Array, String')
  end

  it 'converts from complex types' do
    complex_type = Solargraph::ComplexType.parse('Array', 'String')
    typeset = described_class.from_complex_type(complex_type)
    expect(typeset.to_s).to eq('Array, String')
  end
end
