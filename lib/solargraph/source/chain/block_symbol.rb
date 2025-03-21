# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class BlockSymbol < Link
        def resolve api_map, name_pin, locals
          return [Pin::ProxyType.anonymous(ComplexType::UNDEFINED)] if locals.empty?
          first_arg_return_type = locals.first.return_type
          first_arg_return_type.items.flat_map do |unique_type|
            api_map.get_method_stack(unique_type.tag, word).map do |method_pin|

              Pin::ProxyType.anonymous(method_pin.return_type)
            end
          end
        end
      end
    end
  end
end
