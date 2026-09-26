# frozen_string_literal: true

require 'tmpdir'
require 'open3'

describe Solargraph::Yardoc do
  let(:gemspec) { Gem::Specification.find_by_name('backport') }
  let(:metagem) { Solargraph::Metagem.from_specification(gemspec) }

  describe '.cache' do
    it 'saves yardoc caches from metagems' do
      described_class.cache(metagem)
      expect(File.exist?(described_class.path_for(metagem))).to be(true)
    end
  end

  describe '.load!' do
    it 'loads metagem code objects from metagems' do
      objects = described_class.load!(metagem)
      expect(objects.map(&:name)).to include(:Backport)
    end
  end
end
