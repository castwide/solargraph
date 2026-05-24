# frozen_string_literal: true

module Solargraph
  module Typedef
    module Linker
      class Call < Base
        def resolve
          found = api_map.var_at_location(dictionary.locals, link.word, closure, dictionary.location) if link.head?
          if found
            return delegate(found)
          end

          closure.typedef_return_types
                 .map { |type| type.resolve_rooted(dictionary.api_map, [closure.namespace]) }
                 .flat_map { |type| dictionary.api_map.typedef_path_methods(type.base) }
                 .select { |pin| pin.name == link.word }
        end
      end
    end
  end
end
