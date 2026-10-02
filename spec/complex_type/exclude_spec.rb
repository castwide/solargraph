# frozen_string_literal: true

# ComplexType#exclude accepts an api_map parameter but ignores it,
# doing plain exact-match subtraction instead of also excluding
# known subtypes of an excluded type.
describe Solargraph::ComplexType do
  let(:api_map) { Solargraph::ApiMap.new }

  let(:source) do
    Solargraph::Source.load_string(%(
      class Sup; end
      class Sub < Sup; end
      class Unrelated; end
    ))
  end

  before { api_map.map source }

  it 'excludes known subtypes of an excluded type, not just exact matches' do
    pending 'exclude ignores its api_map parameter and only removes exact matches'
    type = described_class.parse('Sub, Sup, Unrelated')
    result = type.exclude(described_class.parse('Sup'), api_map)
    expect(result.tags).to eq('Unrelated')
  end

  it 'falls back to UNDEFINED when every member is excluded transitively' do
    pending 'exclude ignores its api_map parameter and only removes exact matches'
    type = described_class.parse('Sub, Sup')
    result = type.exclude(described_class.parse('Sup'), api_map)
    expect(result.undefined?).to be(true)
  end
end
