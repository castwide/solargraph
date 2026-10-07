# frozen_string_literal: true

describe Gem::Specification do
  describe 'loaded from solargraph.gemspec' do
    let(:spec) { described_class.load(File.expand_path('../solargraph.gemspec', __dir__)) }

    it "does not package a top-level sig/ directory, which RBS auto-discovers in installed gems and would collide with consumers' own RBS collections" do
      # https://github.com/castwide/solargraph/issues/1144
      expect(spec.files.grep(%r{^sig/})).to be_empty
    end
  end
end
