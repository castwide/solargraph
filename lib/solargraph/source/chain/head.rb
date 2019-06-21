module Solargraph
  class Source
    class Chain
      # Chain::Head is a link for ambiguous words, e.g.; `String` can refer to
      # either a class (`String`) or a function (`Kernel#String`).
      #
      # @note Chain::Head is only intended to handle `self` and `super`.
      class Head < Link
        def resolve api_map, name_pin, locals
          return [Pin::ProxyType.anonymous(name_pin.binder)] if word == 'self'
          return super_pins(api_map, name_pin) if word == 'super'
          []
        end

        private

        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @return [Array<Pin::Base>]
        def super_pins api_map, name_pin
          pins = api_map.get_method_stack(name_pin.namespace, name_pin.name, scope: name_pin.scope)
          pins.reject{|p| p.path == name_pin.path}
        end
      end
    end
  end
end
