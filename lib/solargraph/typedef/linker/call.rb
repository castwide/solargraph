# frozen_string_literal: true

module Solargraph
  module Typedef
    module Linker
      class Call < Base
        def resolve
          local_variable || method_call
        end

        private

        def local_variable
          found = api_map.var_at_location(dictionary.locals, link.word, closure, dictionary.location) if link.head?
          return unless found

          # result = found.probe(api_map)
          # return [found.proxy(result)] if result.defined?
          # return [found]

          # [found]

          return [found] if found.return_type.defined?

          chain = Solargraph::Parser::ParserGem::NodeChainer.chain(found.assignment)
          types = Dictionary.new(api_map, found.filename, found.location.range.start, chain: chain).infer
          [found.proxy(ComplexType.new(types.map(&:to_complex_type)))]
        end

        def method_call
          pins = closure.typedef_return_types
                 .map { |type| type.resolve_rooted(dictionary.api_map, [closure.namespace]) }
                 .flat_map { |type| dictionary.api_map.typedef_type_methods(type) }
                 .select { |pin| pin.name == link.word }
          return pins unless link.nullable?

          pins.map { |pin| pin.proxy(ComplexType.new([pin.return_type, ComplexType::NIL])) }
        end
      end
    end
  end
end
