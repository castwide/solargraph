# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class BlockSymbol < Link
        def resolve _api_map, _name_pin, _locals
          [Pin::ProxyType.anonymous(ComplexType.try_parse('::Proc'), source: :chain)]
        end
      end
    end
  end
end
