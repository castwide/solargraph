# frozen_string_literal: true

describe Solargraph::External do
  let(:external) do
    # We're using a library here because it's the easiest way to spawn a bench
    library = Solargraph::Library.load(File.join('spec', 'fixtures', 'external_bundled_gem'))
    library.map!
    described_class.new(library.bench)
  end

  it 'loads bundled gems' do
    expect(external.loaded_gems.map(&:name)).to match_array(['backport', 'gem-with-yard-macros'])
  end

  it 'loads pins from path sources' do
    pins = external.pins.select { |pin| pin.path&.start_with?('Gem::With::Yard::Macros') }
    expect(pins.length).to be_positive
  end
end
