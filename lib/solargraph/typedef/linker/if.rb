# frozen_string_literal: true

module Solargraph
  module Typedef
    module Linker
      class If < Base
        # @return [Array<Pin::Base>]
        def resolve
          types = link.chains
                      .flat_map { |chain| Dictionary.new(api_map, source_map, nil, chain: chain, closure: receiver).infer }
          [Pin::ProxyType.anonymous(Union.new(types).to_complex_type, closure: receiver)]
        end
      end
    end
  end
end
