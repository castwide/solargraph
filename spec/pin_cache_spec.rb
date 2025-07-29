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
      let(:gem_name) { 'logger' }

      before do
        Solargraph::Shell.new.uncache(gem_name)
      end

      it 'caches' do
        yaml_gemspec = Gem::Specification.find_by_name(gem_name)
        allow(File).to receive(:write).and_call_original

        pin_cache.cache_gem(gemspec: yaml_gemspec, out: nil)

        # match arguments with regexp using rspec-matchers syntax
        expect(File).to have_received(:write).with(%r{combined/logger-.*-stdlib.ser$}, any_args).once
      end
    end

    context 'with gem packaged with its own RBS gem' do
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

  describe '#uncache_gem' do
    subject(:call) { pin_cache.uncache_gem(gemspec, out: out) }

    let(:out) { StringIO.new }

    before do
      allow(FileUtils).to receive(:rm_rf)
    end

    context 'with an already cached gem' do
      let(:gemspec) { Gem::Specification.find_by_name('backport') }

      it 'deletes files' do
        call

        expect(FileUtils).to have_received(:rm_rf).at_least(:once)
      end
    end

    context 'with a non-existent gem' do
      let(:gemspec) { instance_double(Gem::Specification, name: 'nonexistent', version: '0.0.1') }

      it 'does not raise an error' do
        expect { call }.not_to raise_error
      end

      it 'logs a message' do
        call

        expect(out.string).to include('does not exist')
      end

      it 'does not delete files' do
        call

        expect(FileUtils).not_to have_received(:rm_rf)
      end
    end
  end
end
