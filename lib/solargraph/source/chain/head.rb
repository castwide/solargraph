module Solargraph
  class Source
    class Chain
      # Chain::Head is a link for ambiguous words, e.g.; `String` can refer to
      # either a class (`String`) or a function (`Kernel#String`).
      #
      class Head < Call
        def resolve api_map, name_pin, locals
          return [self_pin(api_map, name_pin.context)] if word == 'self'
          return super_pins(api_map, name_pin) if word == 'super'
          base = super
          return base if locals.map(&:name).include?(word)
          here = []
          ns = api_map.qualify(word, name_pin.context.namespace)
          here.concat api_map.get_path_suggestions(ns) unless ns.nil?
          here + base
        end

        private

        def self_pin(api_map, context)
          return Pin::ProxyType.anonymous(context)
        end

        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        def super_pins api_map, name_pin
          pins = api_map.get_method_stack(name_pin.namespace, name_pin.name, scope: name_pin.scope)
          pins.reject{|p| p.path == name_pin.path}
        end
      end
    end
  end
end
