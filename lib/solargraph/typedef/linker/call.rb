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
            api_map.var_at_location(dictionary.locals, link.word, closure, dictionary.location) ||
              # @todo Rough way to access parameters
              (closure.is_a?(Pin::Method) ? closure.parameters.find { |pin| pin.name == link.word } : nil )
          end

          # @todo The linker should probably return the raw pin and let the dictionary handle
          #   inference, but doing it here passes some existing specs

          return unless found
          return [found] if found.return_type.defined?

          chain = Solargraph::Parser::ParserGem::NodeChainer.chain(found.assignment)
          types = Dictionary.new(api_map, found.filename, closure.location.range.start, chain: chain).infer
          [found.proxy(ComplexType.new(types.map(&:to_complex_type)))]
        end

        def method_call
          types = closure.typedef_return_types
                        #  .map { |type| type.resolve_rooted(dictionary.api_map, [closure.context.namespace]) }
          # @todo Quick and dirty hack to force UniqueType to ComplexType
          pins = ComplexType.new([closure.binder]).to_typedef_types
                            .flat_map { |type| dictionary.api_map.typedef_type_methods(type) }
                            .select { |pin| pin.name == link.word }
                            # .flat_map { |pin| overload(pin) }
          return pins unless link.nullable? && closure.typedef_return_types.any?(&:nullable?)

          pins.map { |pin| pin.proxy(ComplexType.new([pin.return_type, ComplexType::NIL])) }
        end

        # @param pin [Pin::Method]
        def overload(pin)
          pin.overloads.find { |overload| overload.arity_matches?(link.arguments, link.arguments )} || pin
        end
      end
    end
  end
end
