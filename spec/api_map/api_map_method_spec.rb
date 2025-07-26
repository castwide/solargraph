# frozen_string_literal: true

describe Solargraph::ApiMap do
  describe '#cache_all_for_workspace!' do
    context 'with workspace' do
      subject(:api_map) { described_class.load(Dir.pwd) }

      let(:out) { StringIO.new }

      it 'processes the request' do
        api_map.cache_all_for_workspace!(out, rebuild: false)

        expect(out.string).to include('Documentation cached')
      end
    end

    context 'with no workspace' do
      subject(:api_map) { described_class.new }

      it 'ignores the request' do
        expect { api_map.cache_all_for_workspace!(nil, rebuild: false) }.not_to raise_error
      end
    end
  end

  describe '#cache_gem' do
    context 'with no workspace' do
      subject(:api_map) { described_class.new }

      let(:out) { StringIO.new }

      it 'ignores the request' do
        expect { api_map.cache_gem('backport', out: out) }.not_to raise_error
      end
    end

    context 'with workspace' do
      subject(:api_map) { described_class.load(Dir.pwd) }

      let(:out) { StringIO.new }

      it 'processes the request' do
        backport = Gem::Specification.find_by_name('backport')
        expect { api_map.cache_gem(backport, out: out) }.not_to raise_error
      end
    end
  end

  describe '.load_with_cache' do
    it 'loads the API map with cache' do
      Solargraph::PinCache.uncache_core

      output = capture_both do
        described_class.load_with_cache(Dir.pwd)
      end

      expect(output).to include('aching RBS pins for Ruby core')
    end
  end

  describe '#get_method_stack' do
    let(:out) { StringIO.new }
    let(:api_map) { described_class.load_with_cache(Dir.pwd, out: out) }
    let(:method_stack) { api_map.get_method_stack('YAML', 'safe_load', scope: :class) }

    it 'handles the YAML gem aliased to Psych' do
      expect(method_stack).not_to be_empty
    end
  end
end
