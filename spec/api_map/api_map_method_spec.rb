# frozen_string_literal: true

describe Solargraph::ApiMap do
  describe 'cache_all_for_workspace!' do
    context 'with no workspace' do
      subject(:api_map) { described_class.new }

      it 'ignores the request' do
        expect { api_map.cache_all_for_workspace!(nil, rebuild: false) }.not_to raise_error
      end
    end
  end
end
