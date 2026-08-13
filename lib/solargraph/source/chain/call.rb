# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      #
      # Handles both method calls and local variable references by
      # first looking for a variable with the name 'word', then
      # proceeding to method signature resolution if not found.
      #
      class Call < Chain::Link
        include Solargraph::Parser::NodeMethods

        # @return [String]
        attr_reader :word

        # @return [Location, nil]
        attr_reader :location

        # @return [::Array<Chain>]
        attr_reader :arguments

        # @return [Chain, nil]
        attr_reader :block

        # @param word [String]
        # @param location [Location, nil]
        # @param arguments [::Array<Chain>]
        # @param block [Chain, nil]
        def initialize word, location = nil, arguments = [], block = nil
          super(word)

          @location = location
          @arguments = arguments
          @block = block
          fix_block_pass
        end

        def with_block?
          !!@block
        end

        # @param api_map [ApiMap]
        # @param name_pin [Pin::Closure] name_pin.binder should give us the type of the object on which 'word' will be invoked
        # @param locals [::Array<Pin::LocalVariable>]
        def resolve api_map, name_pin, locals
          return super_pins(api_map, name_pin) if word == 'super'
          return yield_pins(api_map, name_pin) if word == 'yield'
          found = api_map.var_at_location(locals, word, name_pin, location) if head?

          return inferred_pins([found], api_map, name_pin, locals) unless found.nil?
          binder = name_pin.binder
          # this is a q_call - i.e., foo&.bar - assume result of call
          # will be nil or result as if binder were not nil -
          # chain.rb#maybe_nil will add the nil type later, we just
          # need to worry about the not-nil case

          # @sg-ignore Need to handle duck-typed method calls on union types
          binder = binder.without_nil if nullable?
          # @sg-ignore Need to handle duck-typed method calls on union types
          pin_groups = binder.each_unique_type.map do |context|
            ns_tag = context.namespace == '' ? '' : context.namespace_type.tag
            stack = api_map.get_method_stack(ns_tag, word, scope: context.scope)
            [stack.first].compact
          end
          pin_groups = [] if !api_map.loose_unions && pin_groups.any?(&:empty?)
          pins = pin_groups.flatten.uniq(&:path)
          return [] if pins.empty?
          inferred_pins(pins, api_map, name_pin, locals)
        end

        private

        # @param pins [::Enumerable<Pin::Base>]
        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param locals [::Array<Solargraph::Pin::LocalVariable, Solargraph::Pin::Parameter>]
        # @return [::Array<Pin::Base>]
        def inferred_pins pins, api_map, name_pin, locals
          result = pins.map do |p|
            next p unless p.is_a?(Pin::Method)
            overloads = p.signatures
            # next p if overloads.empty?
            type = ComplexType::UNDEFINED
            # start with overloads that require blocks; if we are
            # passing a block, we want to find a signature that will
            # use it.  If we didn't pass a block, the logic below will
            # reject it regardless

            with_block, without_block = overloads.partition(&:block?)
            # @sg-ignore flow sensitive typing should handle is_a? and next
            # @type Array<Pin::Signature>
            sorted_overloads = with_block + without_block
            # @type [Pin::Signature, nil]
            new_signature_pin = nil
            # @sg-ignore flow sensitive typing should handle is_a? and next
            # @param ol [Pin::Signature]
            sorted_overloads.each do |ol|
              next unless ol.arity_matches?(arguments, with_block?)

              positional_arguments, keyword_argument = split_keyword_argument(arguments, ol)
              atypes = []
              match = positional_arguments_match?(positional_arguments, ol, api_map, name_pin, locals, atypes)
              match &&= keyword_argument_matches?(keyword_argument, ol, api_map, name_pin, locals) if match

              if match
                if ol.block && with_block?
                  block_atypes = ol.block.parameters.map(&:return_type)
                  # @todo Need to add nil check here
                  blocktype = if block.links.map(&:class) == [BlockSymbol]
                                # like the bar in foo(&:bar)
                                block_symbol_call_type(api_map, name_pin.context, block_atypes, locals)
                              else
                                block_call_type(api_map, name_pin, locals)
                              end
                end
                new_signature_pin = ol.resolve_generics_from_context_until_complete(ol.generics, atypes, nil, nil,
                                                                                    blocktype)
                # @todo It shouldn't be necessary to choose either generics or macros
                new_return_type = if new_signature_pin.return_type.defined?
                  new_signature_pin.return_type
                else
                  named_types = p.parameter_names.zip(arguments.map { |arg| ComplexType.try_parse(simple_convert(arg.node).to_s) }).to_h
                  p.typify(api_map).expand(named_types)
                end
                self_type = if head?
                              # If we're at the head of the chain, we called a
                              # method somewhere that marked itself as returning
                              # self.  Given we didn't invoke this on an object,
                              # this must be a method in this same class - so we
                              # use our own self type
                              name_pin.context
                            else
                              # if we're past the head in the chain, whatever the
                              # type of the lhs side is what 'self' will be in its
                              # declaration - we can't just use the type of the
                              # method pin, as this might be a subclass of the
                              # place where the method is defined
                              name_pin.binder
                            end
                # This same logic applies to the YARD work done by
                # 'with_params()'.
                #
                # qualify(), however, happens in the namespace where
                # the docs were written - from the method pin.
                # @todo Need to add nil check here
                if new_return_type.defined?
                  type = with_params(new_return_type.self_to_type(self_type), self_type).qualify(api_map, *p.gates)
                end
                type ||= ComplexType::UNDEFINED
              end
              break if type.defined?
            end
            p = p.with_single_signature(new_signature_pin) unless new_signature_pin.nil?
            next p.proxy(type) if type.defined?
            p
          end
          logger.debug do
            "Call#inferred_pins(name_pin.binder=#{name_pin.binder}, word=#{word}, pins=#{pins.map(&:desc)}, name_pin=#{name_pin}) - result=#{result}"
          end
          result.map do |pin|
            if pin.path == 'Class#new' && name_pin.binder.tag != 'Class'
              reduced_context = name_pin.binder.reduce_class_type
              pin.proxy(reduced_context)
            else
              # @sg-ignore Need to add nil check here
              next pin if pin.return_type.undefined?
              # @sg-ignore Need to add nil check here
              selfy = pin.return_type.self_to_type(name_pin.binder)
              # @sg-ignore Need to add nil check here
              selfy == pin.return_type ? pin : pin.proxy(selfy)
            end
          end
        end

        # A trailing keyword-arguments hash doesn't line up positionally
        # with the method's declared parameters, so it's split off to be
        # matched separately against the keyword/kwrest parameters
        # instead of the positional ones.
        #
        # @param arguments [::Array<Chain>]
        # @param overload [Pin::Signature]
        # @return [::Array(::Array<Chain>, Chain, nil)]
        def split_keyword_argument arguments, overload
          keyword_params = overload.parameters.select { |param| param.keyword? || param.kwrestarg? }
          last_argument = arguments.last
          if !keyword_params.empty? && last_argument.is_a?(Chain) && last_argument.links.last.is_a?(Chain::Hash)
            [arguments[0..-2], last_argument]
          else
            [arguments, nil]
          end
        end

        # @param positional_arguments [::Array<Chain>]
        # @param overload [Pin::Signature]
        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param locals [::Array<Pin::LocalVariable>]
        # @param atypes [::Array<ComplexType>] populated with the inferred type of each positional argument
        # @return [Boolean]
        def positional_arguments_match? positional_arguments, overload, api_map, name_pin, locals, atypes
          positional_params = overload.parameters.reject { |param| param.keyword? || param.kwrestarg? }
          positional_arguments.each_with_index do |arg, idx|
            param = positional_params[idx]
            return positional_params.any?(&:restarg?) if param.nil?

            arg_name_pin = Pin::ProxyType.anonymous(name_pin.context,
                                                    closure: name_pin.closure,
                                                    gates: name_pin.gates,
                                                    source: :chain)
            atype = atypes[idx] ||= arg.infer(api_map, arg_name_pin, locals)
            return false unless param.compatible_arg?(atype, api_map) || param.restarg?
          end
          true
        end

        # @param keyword_argument [Chain, nil]
        # @param overload [Pin::Signature]
        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param locals [::Array<Pin::LocalVariable>]
        # @return [Boolean]
        def keyword_argument_matches? keyword_argument, overload, api_map, name_pin, locals
          return true if keyword_argument.nil?

          # @type [::Hash{::Symbol => Chain}]
          kwargs = convert_hash(keyword_argument.node)
          keyword_params = overload.parameters.select { |param| param.keyword? || param.kwrestarg? }
          named_params = keyword_params.reject(&:kwrestarg?)
          kwrestarg = keyword_params.find(&:kwrestarg?)

          kw_arg_name_pin = Pin::ProxyType.anonymous(name_pin.context,
                                                     closure: name_pin.closure,
                                                     gates: name_pin.gates,
                                                     source: :chain)
          kwargs.each_pair do |key, value_chain|
            param = named_params.find { |p| p.name.to_sym == key }
            if param.nil?
              return false if kwrestarg.nil?
              next
            end
            # @sg-ignore flow sensitive typing needs to infer Hash#each_pair block param types from a local @type tag
            atype = value_chain.infer(api_map, kw_arg_name_pin, locals)
            # @sg-ignore flow sensitive typing needs to infer Hash#each_pair block param types from a local @type tag
            return false unless param.compatible_arg?(atype, api_map)
          end
          named_params.none? { |param| param.decl == :kwarg && !kwargs.key?(param.name.to_sym) }
        end

        # @param docstring [YARD::Docstring]
        # @param context [ComplexType]
        # @return [ComplexType, nil]
        def extra_return_type docstring, context
          if docstring.has_tag?('return_single_parameter') # && context.subtypes.one?
            return context.subtypes.first || ComplexType::UNDEFINED
          elsif docstring.has_tag?('return_value_parameter') && context.value_types.one?
            return context.value_types.first
          end
          nil
        end

        # @param name_pin [Pin::Base]
        # @return [Pin::Method, nil]
        def find_method_pin name_pin
          method_pin = name_pin
          until method_pin.is_a?(Pin::Method)
            # @sg-ignore Need to support this in flow sensitive typing
            method_pin = method_pin.closure
            return if method_pin.nil?
          end
          method_pin
        end

        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @return [::Array<Pin::Base>]
        def super_pins api_map, name_pin
          method_pin = find_method_pin(name_pin)
          return [] if method_pin.nil?
          pins = api_map.get_method_stack(method_pin.namespace, method_pin.name, scope: method_pin.context.scope)
          pins.reject { |p| p.path == name_pin.path }
        end

        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @return [::Array<Pin::Base>]
        def yield_pins api_map, name_pin
          method_pin = find_method_pin(name_pin)
          return [] unless method_pin

          # @param signature_pin [Pin::Signature]
          method_pin.signatures.map(&:block).compact.map do |signature_pin|
            # @sg-ignore Need to add nil check here
            return_type = signature_pin.return_type.qualify(api_map, *name_pin.gates)
            signature_pin.proxy(return_type)
          end
        end

        # @param type [ComplexType]
        # @param context [ComplexType, ComplexType::UniqueType]
        # @return [ComplexType]
        def with_params type, context
          return type unless type.to_s.include?('$')
          ComplexType.try_parse(type.to_s.gsub('$', context.value_types.map(&:rooted_tag).join(', ')).gsub('<>', ''))
        end

        # @return [void]
        def fix_block_pass
          argument = @arguments.last&.links&.first
          @block = @arguments.pop if argument.is_a?(BlockSymbol) || argument.is_a?(BlockVariable)
        end

        # @param api_map [ApiMap]
        # @param context [ComplexType, ComplexType::UniqueType]
        # @param block_parameter_types [::Array<ComplexType>]
        # @param locals [::Array<Pin::LocalVariable>]
        # @return [ComplexType, nil]
        def block_symbol_call_type api_map, context, block_parameter_types, locals
          # Ruby's shorthand for sending the passed in method name
          # to the first yield parameter with no arguments
          # @sg-ignore Need to add nil check here
          block_symbol_name = block.links.first.word
          block_symbol_call_path = "#{block_parameter_types.first}##{block_symbol_name}"
          callee = api_map.get_path_pins(block_symbol_call_path).first
          return_type = callee&.return_type
          # @todo: Figure out why we get unresolved generics at
          #   this point and need to assume method return types
          #   based on the generic type
          # @sg-ignore Need to add nil check here
          return_type ||= api_map.get_path_pins("#{context.subtypes.first}##{block.links.first.word}").first&.return_type
          return_type || ComplexType::UNDEFINED
        end

        # @param api_map [ApiMap]
        # @return [Pin::Block, nil]
        def find_block_pin api_map
          # @sg-ignore Need to add nil check here
          node_location = Solargraph::Location.from_node(block.node)
          return if node_location.nil?
          block_pins = api_map.get_block_pins
          # @sg-ignore Need to add nil check here
          block_pins.find { |pin| pin.location.contain?(node_location) }
        end

        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param locals [::Array<Pin::LocalVariable>]
        # @return [ComplexType, nil]
        def block_call_type api_map, name_pin, locals
          return nil unless with_block?

          block_pin = find_block_pin(api_map)
          # We use the block pin as the closure, as the parameters
          # here will only be defined inside the block itself and we
          # need to be able to see them
          # @sg-ignore Need to add nil check here
          block.infer(api_map, block_pin, locals)
        end

        protected

        # @sg-ignore Fix "Not enough arguments to Module#protected"
        def equality_fields
          # @sg-ignore literal arrays in this module turn into ::Solargraph::Source::Chain::Array
          super + [arguments, block]
        end
      end
    end
  end
end
