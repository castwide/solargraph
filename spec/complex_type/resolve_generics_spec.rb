# frozen_string_literal: true

# A generic takes its value from the receiver's parameters. An
# intersection receiver has one parameter list per conjunct, so the one
# that counts is the conjunct naming the namespace that declared the
# generic.
describe Solargraph::ComplexType do
  let(:api_map) { Solargraph::ApiMap.new }
  let(:array_pin) { api_map.get_path_pins('Array').first }

  def bind tag, context
    described_class.parse(tag).items.first
                   .resolve_generics(array_pin, described_class.parse(context)).tags
  end

  it 'binds from a context that is a single type' do
    expect(bind('::Array<generic<E>>', '::Array<::String>')).to eq('Array<String>')
  end

  it 'binds from the conjunct that declares the generic' do
    expect(bind('::Array<generic<E>>', '::Array<::String> & ::Enumerable')).to eq('Array<String>')
  end

  # Enumerable carries a parameter of its own here, and taking it would
  # bind E to Integer. Array is the namespace that declares E.
  it 'ignores a parameter on a conjunct that declares nothing' do
    expect(bind('::Array<generic<E>>', '::Enumerable<::Integer> & ::Array<::String>'))
      .to eq('Array<String>')
  end

  it 'leaves the generic unbound when no conjunct declares it' do
    expect(bind('::Array<generic<E>>', '::Comparable & ::Enumerable')).to eq('Array')
  end

  it 'binds an intersection receiver from an intersection context' do
    expect(bind('::Array<generic<E>> & ::Enumerable', '::Array<::String> & ::Enumerable'))
      .to eq('Array<String> & Enumerable')
  end
end
