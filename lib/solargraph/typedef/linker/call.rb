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
        # @param pins [Array<Pin::LocalVariable>]
        # @return [Array<Pin::LocalVariable>]
        # @param [Object] pins
        def reduce_local_type pins
          return pins if pins.first.is_a?(Pin::Parameter)
          pins.grep_v(Pin::Parameter)
        end

        def yield_call
          yield_receivers if link.head? && link.word == 'yield'
        end

        def super_call
          super_pins if link.head? && link.word == 'super'
        end

        def method_call
          # @todo Quick and dirty hack to force UniqueType to ComplexType
          pins = ComplexType.new([receiver.context])
                            .to_typedef_typeset
                            .types
                            .flat_map { |type| get_methods(type) }
                            .select { |pin| pin.name == link.word }
                            .map { |pin| find_matching_signature(pin, receiver) }
                            .map { |pin| expand_macros_from_arguments(pin) }
                            .map { |pin| expand_generic_parameters_from_arguments(pin) }
                            .map { |pin| expand_generic_parameters_from_block(pin) }
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

        # Expands the generic parameters of a method call using the block
        # passed at the call site.
        #
        # Some methods declare return types that are determined entirely by
        # their blocks, e.g., +Mutex#synchronize+ is +( +{ () -> generic<X> }
        # -> generic<X> )+. Neither the receiver nor the arguments supply a
        # value for +X+, so it has to be inferred from the block itself.
        #
        # Only the generics shared by the block's return type and the method's
        # return type are bound, leaving generics resolved by the receiver or
        # the arguments untouched.
        #
        # @param pin [Pin::Method, Pin::Signature]
        # @return [Pin::Base]
        def expand_generic_parameters_from_block pin
          return pin unless link.with_block?
          return pin unless pin.is_a?(Pin::Callable)
          return pin if pin.block.nil?

          typeset = pin.typedef_typeset
          return pin unless typeset.generic?

          names = (generic_names(pin.block.typedef_typeset) & generic_names(typeset)).uniq
          return pin if names.empty?
          return pin if block_passed_by_reference?

          inferred = Dictionary.new(api_map, source_map, link.block).infer
          return pin if inferred.undefined?

          named_values = names.to_h { |name| [name, inferred] }
          pin.proxy(typeset.expand(named_values).to_complex_type)
        end

        # Blocks that are not written at the call site cannot be inferred, e.g.
        # +&:to_s+ passes a symbol and +&blk+ passes a variable, and calls
        # without a block have no block chain at all.
        #
        # @return [Boolean]
        def block_passed_by_reference?
          return true if link.block.nil? || link.block.node.nil?

          link.block.links.any? do |block_link|
            block_link.is_a?(Source::Chain::BlockSymbol) || block_link.is_a?(Source::Chain::BlockVariable)
          end
        end

        # The names, e.g., +generic<X>+, of the generic tokens within a
        # Typedef node.
        #
        # @param node [Typedef::Typeset, Typedef::Type, Typedef::Path, Typedef::Token]
        # @return [Array<String>]
        def generic_names node
          case node
          when Typedef::Typeset
            node.types.flat_map { |type| generic_names type }
          when Typedef::Type
            node.all.flat_map { |part| generic_names part }
          when Typedef::Token
            node.generic? ? [node.name] : node.params.flat_map { |par| generic_names Typedef.tokenize(par) }
          else
            []
          end
        end

        # Expands the return type of a method call using YARD macros.
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
                 .map { |pin| expand_self_type(pin) }
        end

        # A superclass method may declare a return type of +self+, which
        # should resolve to the type of the calling context. Detection of
        # +self+ is performed entirely within the Typedef typeset
        # structure, avoiding any reliance on ComplexType.
        #
        # @param pin [Pin::Base]
        # @return [Pin::Base]
        def expand_self_type pin
          typeset = pin.typedef_typeset
          return pin unless selfy?(typeset)
          pin.proxy(typeset.expand({ 'self' => nearest_method_pin.context.to_typedef_typeset }).to_complex_type)
        end

        # True if the given Typedef node contains a +self+ token, either
        # as a base or nested within parameters.
        #
        # @param node [Typedef::Typeset, Typedef::Type, Typedef::Token, Typedef::Path]
        # @return [Boolean]
        def selfy? node
          case node
          when Typedef::Typeset
            node.types.any? { |type| selfy?(type) }
          when Typedef::Type
            node.all.any? { |part| selfy?(part) }
          when Typedef::Token
            node.name == 'self' || node.params.any? { |par| selfy?(Typedef.tokenize(par)) }
          else
            false
          end
        end

        def nearest_method_pin
          @nearest_method_pin ||= begin
            method_pin = receiver
            method_pin = method_pin.closure until method_pin.is_a?(Pin::Method) || method_pin.nil?
            method_pin
          end
        end

        def yield_receivers
          return [] unless nearest_method_pin

          nearest_method_pin.signatures
                            .map(&:block)
                            .compact
        end

        def private_kernel_methods type
          return [] unless link.head?
          api_map.get_methods('Kernel', scope: :instance, visibility: [:private])
        end

        # @param type [Typedef::Type]
        def get_methods type
          namespace = if type.class?
            # @todo Handle multiple
            type.params.first.to_s
          else
            type.base.to_s
          end
          scope = if type.class?
            :class
          else
            :instance
          end
          visibility = method_visibility(type)
          dictionary.api_map.get_methods(namespace, scope: scope, visibility: visibility)
                    .select { |pin| pin.name == link.word }
        end

        # @param type [Typedef::Type]
        # @return [Array<Symbol>]
        def method_visibility type
          return [:public, :private, :protected] if link.head?
          # @todo Stop depending on complex types
          return [:public, :protected] if type.to_complex_type.to_s == dictionary.closure.context.to_s
          [:public]
        end
      end
    end
  end
end
