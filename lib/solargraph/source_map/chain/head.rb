module Solargraph
  class SourceMap
    class Chain
      # Chain::Head is a link for ambiguous words, e.g.; `String` can refer to
      # either a class (`String`) or a function (`Kernel#String`).
      #
      class Head < Call
        def resolve api_map, name_pin, locals
          return [self_pin(api_map, name_pin.context)] if word == 'self'
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
      end
    end
  end
end
