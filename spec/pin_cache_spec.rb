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
        # if this fails, you may not have run `bundle exec rbs collection update`
        expect(Solargraph::Yardoc).not_to have_received(:build_docs)
      end
    end

    context 'with a stdlib gem' do
      let(:gem_name) { 'cgi' }

      before do
        Solargraph::Shell.new.uncache(gem_name)
      end

      it 'caches' do
        yaml_gemspec = Gem::Specification.find_by_name(gem_name)
        allow(File).to receive(:write).and_call_original

        pin_cache.cache_gem(gemspec: yaml_gemspec, out: nil)

        # match arguments with regexp using rspec-matchers syntax
        expect(File).to have_received(:write).with(%r{combined/cgi-.*-stdlib.ser$}, any_args).once
      end
    end

    context 'with a gem packaged with its own RBS' do
      let(:gem_name) { 'base64' }

      before do
        Solargraph::Shell.new.uncache(gem_name)
      end

      it 'caches' do
        yaml_gemspec = Gem::Specification.find_by_name(gem_name)
        allow(File).to receive(:write).and_call_original

        pin_cache.cache_gem(gemspec: yaml_gemspec, out: nil)

        # match arguments with regexp using rspec-matchers syntax
        expect(File).to have_received(:write).with(%r{combined/base64-.*-export.ser$}, any_args).once
      end
    end
  end
end
