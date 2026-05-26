# frozen_string_literal: true

module Solargraph
  module Typedef
    module Linker
      class ClassVariable < Base
        def resolve
          found = api_map.get_class_variable_pins(closure.context.namespace).select { |p| p.name == link.word }.first
          return [] unless found

          chain = Solargraph::Parser::ParserGem::NodeChainer.chain(found.assignment)
          types = Dictionary.new(api_map, found.filename, found.location.range.start, chain: chain).infer
          [found.proxy(ComplexType.new(types.map(&:to_complex_type)))]
        end
      end
    end
  end
end
