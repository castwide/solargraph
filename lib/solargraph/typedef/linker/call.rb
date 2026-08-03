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
          return receiver.signatures.map(&:block).compact if link.word == 'yield'

          # @todo Quick and dirty hack to force UniqueType to ComplexType
          pins = ComplexType.new([receiver.context]).to_typedef_types
                            .flat_map { |type| dictionary.api_map.typedef_type_methods(type) }
                            .select { |pin| pin.name == link.word }
                            .map { |pin| find_matching_signature(pin, receiver) }
                            .map { |pin| expand_generic_parameters_from_arguments(pin) }
                            .map { |pin| expand_macros_from_arguments(pin) }
          return pins unless link.nullable? && receiver.typedef_typeset.nullable?

          pins.map { |pin| pin.proxy(ComplexType.new([pin.return_type, ComplexType::NIL])) }
        end

        # @param pin [Pin::Method]
        # @return [Pin::Signature, Pin::Method]
        def find_matching_signature(pin, receiver)
          pin.signatures.each do |signature|
            next unless signature.arity_matches?(link.arguments, link.with_block?)

            arguments = link.arguments.map do |arg|
              Dictionary.new(api_map, source_map, Range.from_node(arg.node).start, chain: arg).infer
            end
            match = true
            signature.parameters.each.with_index do |par, idx|
              next if compatible_arg?(par, arguments[idx])
              match = false
              break
            end
            return signature if match
          end
          pin
        end

        def compatible_arg? parameter, argument
          return true if parameter.typedef_typeset.to_complex_type.undefined? ||
            parameter.typedef_typeset.generic?
          # @todo Conformance needs to work for typesets
          atype = argument&.to_complex_type || ComplexType::UNDEFINED
            atype.conforms_to?(api_map, parameter.typedef_typeset.to_complex_type, :method_call, %i[allow_empty_params allow_undefined])
        end

        # Expanding generic parameters needs to be done here because we need to
        # infer values from the call link's arguments.
        #
        def expand_generic_parameters_from_arguments pin
          return pin unless pin.is_a?(Pin::Callable)
          # return pin unless pin.typedef_typeset.generic?
          return pin unless pin.parameters.map(&:typedef_typeset).any?(&:generic?)

          named_values = {}
          pin.parameters.map.with_index do |param, idx|
            arg = Dictionary.new(api_map, source_map, param.location.range.start, chain: link.arguments[idx]).infer
            next_hash = param.typedef_typeset.extract_generics(arg)
            named_values.merge! next_hash
          end
          expanded = pin.typedef_typeset.expand(named_values)
          pin.proxy(expanded.to_complex_type)
        end

        # @param pin [Pin::Method]
        def expand_macros_from_arguments pin
          return pin unless pin.closure.maybe_directives?

          pin.closure.directives.each do |directive|
            macro = Solargraph::YardMap::Macro.from_directive(pin.closure.directives.first, pin.closure)
            expanded = macro.macro_object.expand([pin.name, *pin.parameter_names])
            docstring = Solargraph::Source.parse_docstring(expanded).to_docstring
            types = docstring.tags(:return).flat_map(&:types)
            complex_type = ComplexType.try_parse(*types)
            pin = pin.proxy(complex_type)
          end
          arguments = pin.parameters.map.with_index do |param, idx|
            token = Typedef.tokenize(Solargraph::Parser::ParserGem::NodeMethods.simple_convert(link.arguments[idx].node))
            Typeset.new([Type.new(token)])
          end
          named_values = pin.parameter_names.zip(arguments).to_h
          pin.proxy(pin.typedef_typeset.expand(named_values).to_complex_type)
        end
      end
    end
  end
end
