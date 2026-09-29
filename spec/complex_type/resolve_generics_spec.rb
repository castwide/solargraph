# frozen_string_literal: true

# A generic takes its value from the receiver's parameters. An
# intersection receiver has one parameter list per conjunct, so the one
# that counts is the conjunct naming the namespace that declared the
# generic.
#
# The generic is declared here rather than borrowed from a core class,
# whose type parameter is named differently across RBS versions.
describe Solargraph::ComplexType do
  let(:api_map) do
    Solargraph::ApiMap.new.tap do |map|
      map.map Solargraph::Source.load_string(<<~RUBY, 'test.rb')
        # @generic E
        class Box; end
      RUBY
    end
  end

  let(:box_pin) { api_map.get_path_pins('Box').first }

  def bind tag, context
    described_class.parse(tag).items.first
                   .resolve_generics(box_pin, described_class.parse(context)).tags
  end

  it 'binds from a context that is a single type' do
    expect(bind('Box<generic<E>>', 'Box<::String>')).to eq('Box<String>')
  end

  it 'binds from the conjunct that declares the generic' do
    expect(bind('Box<generic<E>>', 'Box<::String> & ::Enumerable')).to eq('Box<String>')
  end

  # Enumerable carries a parameter of its own here, and taking it would
  # bind E to Integer. Box is the namespace that declares E.
  it 'ignores a parameter on a conjunct that declares nothing' do
    expect(bind('Box<generic<E>>', '::Enumerable<::Integer> & Box<::String>')).to eq('Box<String>')
  end

  it 'leaves the generic unbound when no conjunct declares it' do
    expect(bind('Box<generic<E>>', '::Comparable & ::Enumerable')).to eq('Box')
  end

  it 'binds an intersection receiver from an intersection context' do
    expect(bind('Box<generic<E>> & ::Enumerable', 'Box<::String> & ::Enumerable'))
      .to eq('Box<String> & Enumerable')
  end
end
