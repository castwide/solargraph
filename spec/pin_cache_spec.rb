# frozen_string_literal: true

require 'bundler'
require 'benchmark'

describe Solargraph::PinCache do
  subject(:pin_cache) do
    described_class.new(rbs_collection_path: '.gem_rbs_collection',
                        rbs_collection_config_path: 'rbs_collection.yaml',
                        directory: Dir.pwd,
                        yard_plugins: [])
  end

  describe '#possible_stdlibs' do
    it 'is tolerant of less usual Ruby installations' do
      stub_const('Gem::RUBYGEMS_DIR', nil)

      expect(pin_cache.possible_stdlibs).to eq([])
    end
  end

  describe '#cache_gem' do
    context 'with an already in-memory gem' do
      let(:backport_gemspec) { Gem::Specification.find_by_name('backport') }

      before do
        pin_cache.cache_gem(gemspec: backport_gemspec, out: nil)
      end

      it 'does not load the gem again' do
        allow(Marshal).to receive(:load).and_call_original

        pin_cache.cache_gem(gemspec: backport_gemspec, out: nil)

        expect(Marshal).not_to have_received(:load).with(anything)
      end
    end

    context 'with the parser gem' do
      before do
        Solargraph::Shell.new.uncache('parser')
        allow(Solargraph::Yardoc).to receive(:build_docs)
      end

      it 'chooses not to use YARD' do
        parser_gemspec = Gem::Specification.find_by_name('parser')
        pin_cache.cache_gem(gemspec: parser_gemspec, out: nil)
        expect(Solargraph::Yardoc).not_to have_received(:build_docs)
      end
    end
  end
end
