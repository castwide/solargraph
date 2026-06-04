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
          # @todo We shouldn't need to check for local variables here. Local variables
          #   are always the head of the chain, so they should go to the Head link.
          #   This change will require a change to the way chainers work, so it might
          #   have to wait until processes outside of Typedef stop using chains.
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
                            .map { |pin| find_matching_signature(pin, closure) }
                            .map { |pin| expand_generic_parameters_from_arguments(pin) }
          return pins unless link.nullable? && closure.typedef_typeset.nullable?

          pins.map { |pin| pin.proxy(ComplexType.new([pin.return_type, ComplexType::NIL])) }
        end

        # @param pin [Pin::Method]
        # @return [Pin::Signature, Pin::Method]
        def find_matching_signature(pin, receiver)
          pin.signatures.each do |signature|
            # @todo Match on more precise criteria than mere argument length
            next unless signature.arity_matches?(link.arguments, link.with_block?)

            return signature
          end

          pin
        end

        # Expanding generic parameters needs to be done here because we need to
        # infer values from the call link's arguments.
        #
        def expand_generic_parameters_from_arguments pin
          return pin unless pin.is_a?(Pin::Callable)
          return pin unless pin.typedef_typeset.generic?
          return pin unless pin.parameters.map(&:typedef_typeset).any?(&:generic?)

          named_values = pin.parameters.map.with_index do |param, idx|
            next unless param.typedef_typeset.generic?

            key = param.typedef_typeset.to_s
            val = Dictionary.new(api_map, source_map, param.location.range.start, chain: link.arguments[idx]).infer
            [key, val]
          end
          .compact
          .to_h

          pin.proxy(pin.typedef_typeset.expand(named_values).to_complex_type)
        end
      end
    end
  end
end
