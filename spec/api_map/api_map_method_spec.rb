# frozen_string_literal: true

require 'tmpdir'

describe Solargraph::ApiMap do
  describe '.load_with_cache' do
    it 'loads the API map with cache', time_limit_seconds: 120 do
      Solargraph::PinCache.uncache_core

      output = Dir.mktmpdir do |dir|
        capture_both do
          described_class.load_with_cache(dir)
        end
      end

      expect(output).to include('aching RBS pins for Ruby core')
    end
  end

  describe '#get_method_stack', time_limit_seconds: 120 do
    let(:out) { StringIO.new }
    let(:api_map) { described_class.load_with_cache(Dir.pwd, out) }

    context 'with stdlib that has vital dependencies' do
      let(:method_stack) { api_map.get_method_stack('YAML', 'safe_load', scope: :class) }

      it 'handles the YAML gem aliased to Psych' do
        expect(method_stack).not_to be_empty
      end
    end

    context 'with thor' do
      let(:method_stack) { api_map.get_method_stack('Thor', 'desc', scope: :class) }

      it 'handles finding Thor.desc' do
        expect(method_stack).not_to be_empty
      end
    end
  end
end
