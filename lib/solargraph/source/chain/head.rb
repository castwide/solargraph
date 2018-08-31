module Solargraph
  class Source
    class Chain
      # Chain::Head is a link for ambiguous words, e.g.; `String` can refer to
      # either a class (`String`) or a function (`Kernel#String`).
      #
      class Head < Call
        def resolve api_map, context, locals
          return [self_pin(api_map, context)] if word == 'self'
          base = super
          return base if locals.map(&:name).include?(word)
          here = []
          ns = api_map.qualify(word, context.named_context)
          here.concat api_map.get_path_suggestions(ns) unless ns.nil?
          here + base
        end
      end
    end
  end
end
