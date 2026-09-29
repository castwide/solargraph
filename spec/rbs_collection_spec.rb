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
      metagem = double(Solargraph::Metagem, name: 'addressable', version: '2.8.0')
      pins = rbs_collection.load(metagem)
      addressable_uri_pins = pins.select { |pin| pin.path == 'Addressable::URI' }
      expect(addressable_uri_pins.length).to be_positive
    end
  end
end
