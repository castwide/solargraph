# frozen_string_literal: true

module Solargraph
  module Typedef
    module Linker
      class Call < Base
        def resolve
          found = api_map.var_at_location(dictionary.locals, link.word, closure, dictionary.location) if link.head?
          if found
            # @todo Pin probing is still necessary for local variables
            # lchain = Solargraph::Parser::ParserGem::NodeChainer.chain(found.assignment)
            # inf = Dictionary.new(api_map, found.filename, found.location.range.start, chain: lchain)
            #                 .infer
            #                 # @todo Not sure why a generic<T> type is getting inferred in
            #                 #   spec\typedef\call_spec.rb:429
            #                 .select(&:expanded?)
            # return [found] if inf.empty?
            # result = ComplexType.new(inf.map(&:to_complex_type))
            # return [Pin::ProxyType.anonymous(result)] if result.defined?
            # return [found]

            result = found.probe(api_map)
            return [Pin::ProxyType.anonymous(result)] if result.defined?
            return [found]
          end

          closure.typedef_return_types
                 .map { |type| type.resolve_rooted(dictionary.api_map, [closure.namespace]) }
                 .flat_map { |type| dictionary.api_map.typedef_type_methods(type) }
                 .select { |pin| pin.name == link.word }
        end
      end
    end
  end
end
