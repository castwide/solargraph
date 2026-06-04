# frozen_string_literal: true

module Solargraph
  module Typedef
    module Linker
      # @!method link
      #   return [Source::Chain::Call]
      class Call < Base
        # @todo Candidate for deprecation
        include Solargraph::Parser::NodeMethods

        def resolve
          local_variable || method_call
        end

        private

        def local_variable
          found = if link.head?
            source_map.locals_at(dictionary.location)
                      .reverse
                      .find { |pin| pin.name == link.word }
          end
          return [found] if found
        end

        def method_call
          # @todo Quick and dirty hack to force UniqueType to ComplexType
          pins = ComplexType.new([closure.context]).to_typedef_types
                            .flat_map { |type| dictionary.api_map.typedef_type_methods(type) }
                            .select { |pin| pin.name == link.word }
          return pins unless link.nullable? && closure.typedef_typeset.nullable?

          pins.map { |pin| pin.proxy(ComplexType.new([pin.return_type, ComplexType::NIL])) }
        end
      end
    end
  end
end
