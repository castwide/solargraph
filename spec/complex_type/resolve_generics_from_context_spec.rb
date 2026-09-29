# frozen_string_literal: true

# Binding a generic walks a type's parameters. A parameter is a union, a
# named type or an intersection, and only the first has members to take
# apart - so the walk asks what kind it is rather than assuming.
describe Solargraph::ComplexType do
  def bind tag, context
    described_class.parse(tag).items.first
                   .resolve_generics_from_context(['E'], described_class.parse(context)).tags
  end

  it 'binds a generic in a plain parameter' do
    expect(bind('::Array<generic<E>>', '::Array<::String>')).to eq('Array<String>')
  end

  it 'binds a generic held inside an intersection parameter' do
    expect(bind('::Array<[generic<E> & ::Comparable]>', '::Array<::String>'))
      .to eq('Array<String & Comparable>')
  end

  # The outer intersection is incidental; the parameter position is what
  # decides whether the walk meets one.
  it 'binds through an intersection parameter under an intersection' do
    expect(bind('::Array<[generic<E> & ::Comparable]> & ::Enumerable', '::Array<::String>'))
      .to eq('Array<String & Comparable> & Enumerable')
  end
end
