# frozen_string_literal: true

describe Solargraph::External do
  let(:directory) { File.join('spec', 'fixtures', 'external_bundled_gem') }
  let(:requires) { ['backport', 'gem/with/yard/macros'] }
  let(:external) { described_class.new(directory, requires) }

  it 'loads bundled gems' do
    expect(external.loaded_gems.map(&:name)).to match_array(['backport', 'gem-with-yard-macros'])
  end

  it 'loads pins from path sources' do
    pins = external.pins.select { |pin| pin.path&.start_with?('Gem::With::Yard::Macros') }
    expect(pins.length).to be_positive
  end
end
