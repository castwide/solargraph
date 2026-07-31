# frozen_string_literal: true

# ComplexType#exclude already accepts an api_map parameter, but its
# current implementation ignores it and does plain exact-match array
# subtraction. This documents the api_map-aware behavior it would
# ideally have (a third example of api-map-driven type simplification,
# alongside narrow_with's subtype/mix-in reduction and qualify's name
# resolution): excluding a type should also exclude any union member
# already known to be one of its subtypes, since a value that fails
# `is_a?(Sup)` can't be a `Sub` either.
#
# Not implemented - out of scope for the PR that added this file.
# These specs exist so the gap is tracked rather than silently unknown.
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
