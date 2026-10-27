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
          local_variable || yield_call || super_call || method_call
        end

        private

        def local_variable
          found = if link.head?
                    source_map.locals_at(dictionary.location)
                              .reverse
                              .select { |pin| pin.name == link.word }
                  end
          reduce_local_type(found) if found&.any?
        end

        # Local variables supersede parameters
        #
        # @param [Array<Pin::LocalVariable>]
        # @return [Array<Pin::LocalVariable>]
        def reduce_local_type pins
          return pins if pins.first.is_a?(Pin::Parameter)
          pins.reject { |pin| pin.is_a?(Pin::Parameter) }
        end

        def yield_call
          yield_receivers if link.head? && link.word == 'yield'
        end

        def super_call
          super_pins if link.head? && link.word == 'super'
        end

        def method_call
          # @todo Quick and dirty hack to force UniqueType to ComplexType
          pins = ComplexType.new([receiver.context]).to_typedef_types
                            .flat_map { |type| dictionary.api_map.typedef_type_methods(type) }
                            .select { |pin| pin.name == link.word }
                            .map { |pin| find_matching_signature(pin, receiver) }
                            .map { |pin| expand_macros_from_arguments(pin) }
                            .map { |pin| expand_generic_parameters_from_arguments(pin) }
          return pins unless link.nullable? && receiver.typedef_typeset.nullable?

          pins.map { |pin| pin.proxy(ComplexType.new([pin.return_type, ComplexType::NIL])) }
        end

        # @param pin [Pin::Method]
        # @return [Pin::Signature, Pin::Method]
        # @param receiver [Pin::Closure]
        def find_matching_signature pin, receiver
          signatures = pin.is_a?(Pin::Method) ? pin.signatures : [pin]
          signatures.each do |signature|
            next unless signature.arity_matches?(link.arguments, link.with_block?)
            next if !signature.block? && link.with_block?

            arguments = link.arguments.map do |arg|
              Dictionary.new(api_map, source_map, arg).infer
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
            arg = Dictionary.new(api_map, source_map, link.arguments[idx]).infer
            next_hash = param.typedef_typeset.extract_generics(arg)
            named_values.merge! next_hash
          end
          expanded = pin.typedef_typeset.expand(named_values)
          pin.proxy(expanded.to_complex_type)
        end

        # Expands the return type of a method call using YARD macros.
        #
        # A method can acquire a return type from two kinds of macros:
        #
        # * Named macros referenced in the pin's docstring with
        #   +@macro name+. The macro definition is looked up by name in the
        #   ApiMap.
        # * Anonymous macros declared with a +@!macro+ directive that
        #   carries the macro text inline at the pin's definition.
        #
        # Macro placeholders (e.g., +$1+) expand to the method's parameter
        # names, then the parameters are replaced with types inferred from
        # the arguments passed to this call site.
        #
        # @param pin [Pin::Method, Pin::Signature]
        # @return [Pin::Base]
        def expand_macros_from_arguments pin
          anonymous = anonymous_macros(pin)
          names = macro_reference_names(pin)
          return pin unless names.any? || anonymous.any?

          types = names.filter_map do |mac|
            macro = api_map.named_macro(mac)
            next unless macro
            return_types_from_macro(macro, pin)
          end.flatten
          anonymous.each do |macro|
            types.concat return_types_from_macro(macro, pin)
          end
          return pin if types.empty?

          pin = pin.proxy(ComplexType.try_parse(*types))
          named_values = {}
          pin.parameters.each_with_index do |param, idx|
            arg = link.arguments[idx]
            next if arg.nil?
            token = Typedef.tokenize(Solargraph::Parser::ParserGem::NodeMethods.simple_convert(arg.node))
            named_values[param.name] = Typeset.new([Type.new(token)])
          end
          pin.proxy(pin.typedef_typeset.expand(named_values).to_complex_type)
        end

        # The named macros referenced by the pin's docstring. When the pin is
        # an @overload signature, the references may be documented on the
        # method instead of on the signature.
        #
        # @param pin [Pin::Method, Pin::Signature]
        # @return [Array<String>]
        def macro_reference_names pin
          names = pin.macro_names
          names += pin.closure.macro_names if pin.is_a?(Pin::Signature) && pin.closure
          names.uniq
        end

        # Anonymous macros are @!macro directives with no name that carry
        # their macro data inline. Named macro definitions and references
        # are excluded.
        #
        # @param pin [Pin::Method, Pin::Signature]
        # @return [Array<Solargraph::YardMap::Macro>]
        def anonymous_macros pin
          return [] unless pin.closure&.maybe_directives?
          declarations = pin.closure.directives.select do |directive|
            directive.tag.tag_name == 'macro' && directive.tag.name.to_s.empty? && !directive.tag.text.to_s.empty?
          end
          declarations.map { |directive| Solargraph::YardMap::Macro.from_directive(directive, pin.closure) }
        end

        # @param macro [Solargraph::YardMap::Macro]
        # @param pin [Pin::Method, Pin::Signature]
        # @return [Array<String>]
        def return_types_from_macro macro, pin
          expanded = macro.macro_object.expand([pin.name, *pin.parameter_names])
          Solargraph::Source.parse_docstring(expanded).to_docstring.tags(:return).flat_map(&:types)
        end

        # @return [::Array<Pin::Base>]
        def super_pins
          return [] unless nearest_method_pin
          api_map.get_method_stack(nearest_method_pin.namespace, nearest_method_pin.name, scope: nearest_method_pin.context.scope)
                 .reject { |pin| pin.path == nearest_method_pin.path }
        end

        def nearest_method_pin
          @nearest_method_pin ||= begin
            method_pin = receiver
            method_pin = method_pin.closure until method_pin.is_a?(Pin::Method) || method_pin.nil?
            method_pin
          end
        end

        def yield_receivers
          nearest_method_pin&.signatures
                            &.map(&:block)
                            &.compact || []
        end
      end
    end
  end
end
