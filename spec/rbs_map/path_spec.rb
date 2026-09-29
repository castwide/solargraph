# frozen_string_literal: true

describe Solargraph::RbsMap::Path do
  let(:path) { File.join('spec', 'fixtures', 'rbs_collection', 'shims') }

  before { described_class.uncache }

  after { described_class.uncache }

  it 'converts a path once' do
    converted = described_class.pins(path)
    expect(described_class.pins(path)).to be(converted)
  end

  it 'keys the cache by path' do
    other = File.join('spec', 'fixtures', 'rbs_collection', '.gem_rbs_collection', 'addressable', '2.8')
    converted = described_class.pins(path)
    described_class.pins(other)
    expect(described_class.pins(path)).to be(converted)
  end

  it 'converts again after uncaching' do
    before_uncache = described_class.pins(path)
    described_class.uncache
    expect(described_class.pins(path)).not_to be(before_uncache)
  end
end
