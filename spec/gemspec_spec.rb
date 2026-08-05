# frozen_string_literal: true

describe Gem::Specification do
  describe 'loaded from solargraph.gemspec' do
    let(:spec) { described_class.load(File.expand_path('../solargraph.gemspec', __dir__)) }

    it 'does not package a top-level sig/ directory that RBS auto-discovers in installed gems' do
      # A prior sig/shims directory collided with consumers' own RBS
      # collections (see https://github.com/castwide/solargraph/issues/1144).
      # The shims now live under rbs/shims instead, which RBS does not scan
      # automatically.
      expect(spec.files.grep(%r{^sig/})).to be_empty
    end
  end
end
