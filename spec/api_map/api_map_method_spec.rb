# frozen_string_literal: true

describe Solargraph::ApiMap do
  describe 'cache_all_for_workspace!' do
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
end
