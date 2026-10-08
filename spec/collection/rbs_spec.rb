# frozen_string_literal: true

describe Solargraph::Collection::Rbs do
  let(:path) { File.join('spec', 'fixtures', 'rbs_collection', '.gem_rbs_collection', 'addressable', '2.8') }

  before { Solargraph::Collection.clear_mem_cache }

  it 'caches pins to disk' do
    described_class.load(path)
    expect(File).to be_file(described_class.new(path).cache_file)
  end

  it 'serves a collection from the cache' do
    # Converting a collection costs more than the rest of the map put
    # together, so a second process must not repeat it.
    converted = described_class.load(path).map(&:path)
    Solargraph::Collection.clear_mem_cache
    expect(described_class.load(path).map(&:path)).to eq(converted)
  end

  it 'keys the cache by collection path' do
    other = File.join('spec', 'fixtures', 'rbs_collection', 'shims')
    expect(described_class.new(path).cache_file).not_to eq(described_class.new(other).cache_file)
  end
end
