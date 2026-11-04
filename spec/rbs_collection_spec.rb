# frozen_string_literal: true

require 'tmpdir'

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

  describe 'gems without a path' do
    let(:lockfile) { File.join('spec', 'fixtures', 'rbs_collection_no_path', 'rbs_collection.lock.yaml') }

    it 'leaves them out of the gem keys' do
      expect(rbs_collection.gem_keys).to be_empty
    end

    it 'returns no pins for them' do
      metagem = instance_double(Solargraph::Metagem, name: 'pathless_fixture', version: '1.0')
      expect(rbs_collection.load(metagem)).to eq([])
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

  describe 'a malformed lockfile' do
    it 'raises a TypeError when the lockfile is not a Hash' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'rbs_collection.lock.yaml')
        File.write(path, "- not_a_hash\n")
        expect { described_class.new(path).gem_keys }.to raise_error(TypeError, /rbs_collection\.lock\.yaml/)
      end
    end

    it 'raises a TypeError when gems is not an Array of Hashes' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'rbs_collection.lock.yaml')
        File.write(path, "gems:\n- not_a_hash\n")
        expect { described_class.new(path).gem_keys }.to raise_error(TypeError, /rbs_collection\.lock\.yaml/)
      end
    end
  end
end
