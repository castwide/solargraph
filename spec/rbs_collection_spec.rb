# frozen_string_literal: true

describe Solargraph::RbsCollection do
  let(:lockfile) { File.join('spec', 'fixtures', 'rbs_collection', 'rbs_collection.lock.yaml') }
  let(:rbs_collection) { described_class.new(lockfile) }

  describe '#gem_keys' do
    it 'returns keys from gem_rbs_collection' do
      expect(rbs_collection.gem_keys).to include('addressable-0')
    end
  end

  describe '#load' do
    it 'returns pins from gem_rbs_collection' do
      metagem = instance_double(Solargraph::Metagem, name: 'addressable', version: '2.8.0')
      pins = rbs_collection.load(metagem)
      addressable_uri_pins = pins.select { |pin| pin.path == 'Addressable::URI' }
      expect(addressable_uri_pins.length).to be_positive
    end
  end

  describe '#stdlib_names' do
    let(:lockfile) { File.join('spec', 'fixtures', 'rbs_collection_stdlib', 'rbs_collection.lock.yaml') }

    it 'returns the names of stdlib signature sets in the lockfile' do
      expect(rbs_collection.stdlib_names).to eq(['date'])
    end

    it 'is empty when the lockfile has no stdlib entries' do
      expect(described_class.new(
        File.join('spec', 'fixtures', 'rbs_collection', 'rbs_collection.lock.yaml')
      ).stdlib_names).to be_empty
    end
  end

  describe 'version matching' do
    let(:lockfile) { File.join('spec', 'fixtures', 'rbs_collection_versions', 'rbs_collection.lock.yaml') }

    it 'selects the highest collection version that does not exceed the gem' do
      metagem = instance_double(Solargraph::Metagem, name: 'collection_version_fixture', version: '7.0.10')
      pins = rbs_collection.load(metagem)
      expect(pins.map(&:path)).to include('CollectionVersionFixture#from_six')
    end

    it 'selects a newer collection version for a newer gem' do
      metagem = instance_double(Solargraph::Metagem, name: 'collection_version_fixture', version: '7.2.1')
      pins = rbs_collection.load(metagem)
      expect(pins.map(&:path)).to include('CollectionVersionFixture#from_seven_one')
    end

    it 'falls back to the lowest collection version for an older gem' do
      metagem = instance_double(Solargraph::Metagem, name: 'collection_version_fixture', version: '5.2.0')
      pins = rbs_collection.load(metagem)
      expect(pins.map(&:path)).to include('CollectionVersionFixture#from_six')
    end
  end
end
