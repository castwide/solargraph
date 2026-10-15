# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class BlockSymbol < Link
        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param locals [::Array<Pin::Base>]
        # @param _receiver_path [::Array<String>, nil]
        def resolve api_map, name_pin, locals, _receiver_path = nil
          [Pin::ProxyType.anonymous(ComplexType.try_parse('::Proc'), source: :chain)]
        end
      end
    end
  end
end
