# frozen_string_literal: true

# #namespace answers where to look a method up. Class<Foo> and
# Module<Foo> stand in for their parameter, since a method called on
# them resolves against Foo.
describe Solargraph::ComplexType do
  def namespace_of tag
    described_class.parse(tag).namespace
  end

  it 'is the type name for an ordinary type' do
    expect(namespace_of('::String')).to eq('String')
  end

  it 'is the parameter for a class or module type' do
    expect(namespace_of('::Class<::Foo>')).to eq('Foo')
    expect(namespace_of('::Module<::Foo>')).to eq('Foo')
  end

  # Foo & Bar names two things at once, so it cannot stand in for one
  # namespace. Class is what the value is, and is the safe answer.
  it 'falls back to the type name when the parameter names no one thing' do
    expect(namespace_of('::Class<[::Foo & ::Bar]>')).to eq('Class')
  end
end
