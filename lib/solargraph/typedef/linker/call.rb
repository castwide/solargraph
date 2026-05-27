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
          # return pins unless link.nullable? && closure.typedef_return_types.any?(&:nullable?)

          # pins.map { |pin| pin.proxy(ComplexType.new([pin.return_type, ComplexType::NIL])) }
        end

        # @param pin [Pin::Method]
        def overload(pin)
          pin.overloads.find { |overload| overload.arity_matches?(link.arguments, link.arguments )} || pin
        end

        # @todo Legacy stuff

        def select_signatures original_pin
          return original_pin # @todo signatures are stubbed
          result = proc do
            signatures = original_pin.signatures
            with_block, without_block = signatures.partition(&:block?)
            sorted_signatures = with_block + without_block
            sorted_signatures.each do |sig|
              match = true
              arg_types = []
              next unless sig.arity_matches?(link.arguments, link.with_block?)
              link.arguments.each_with_index do |arg, idx|
                param = sig.parameters[idx]
                if param.nil?
                  match = sig.parameters.any?(&:restarg?)
                  break
                end
                arg_name_pin = Pin::ProxyType.anonymous(closure.context, closure: closure.closure, gates: closure.gates, source: :chain)
                arg_typedef_types = Dictionary.new(api_map, source_map, closure.location&.range&.start, chain: arg, closure: closure).infer
                arg_type = arg_types[idx] ||= ComplexType.new(arg_typedef_types.map(&:to_complex_type))
                unless param.compatible_arg?(arg_type, api_map) || param.restarg?
                  match = false
                  break
                end
              end
              if match
                if sig.block && link.with_block?
                  block_arg_types = sig.block.parameters.map(&:return_type)
                  blocktype = if link.block.links.map(&:class) == [Source::Chain::BlockSymbol]
                    block_symbol_call_type(api_map, closure.context, block_arg_types, locals)
                  else
                    block_call_type(api_map, closure)
                  end
                end
                new_signature_pin = sig.resolve_generics_from_context_until_complete(sig.generics, arg_types, nil, nil, blocktype)
                new_return_type = if new_signature_pin.return_type.defined?
                  new_signature_pin.return_type
                else
                  named_types = original_pin.parameter_names.zip(link.arguments.map { |arg| ComplexType.try_parse(simple_convert(arg.node).to_s) }).to_h
                  original_pin.typify(api_map).expand(named_types)
                end
                self_type = if link.head?
                  closure.context
                else
                  closure.binder
                end
                type = if new_return_type.defined?
                  with_params(new_return_type.self_to_type(self_type), self_type).qualify(api_map, *original_pin.gates)
                else
                  ComplexType::UNDEFINED
                end
                break if type.defined?
              end
              pin = original_pin.with_single_signature(new_signature_pin) unless new_signature_pin.nil?
              next pin.proxy(type) if type&.defined?
              original_pin
            end
          end.call&.compact
          return original_pin if result.nil? || result.empty?
          result.map do |pin|
            # @todo Nasty hacks to fix signature shortcomings
            pin.name = original_pin.name
            pin.closure = original_pin.closure
            pin.context = original_pin.context
            pin.scope = original_pin.scope
            pin
          end
        end

        # @param type [ComplexType]
        # @param context [ComplexType, ComplexType::UniqueType]
        # @return [ComplexType]
        def with_params type, context
          return type unless type.to_s.include?('$')
          ComplexType.try_parse(type.to_s.gsub('$', context.value_types.map(&:rooted_tag).join(', ')).gsub('<>', ''))
        end

        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param locals [::Array<Pin::LocalVariable>]
        # @return [ComplexType, nil]
        def block_call_type api_map, name_pin
          return nil unless link.with_block?

          block_pin = find_block_pin(api_map)
          # We use the block pin as the closure, as the parameters
          # here will only be defined inside the block itself and we
          # need to be able to see them
          # @sg-ignore Need to add nil check here
          link.block.infer(api_map, block_pin, dictionary.locals)
        end

        # @param api_map [ApiMap]
        # @return [Pin::Block, nil]
        def find_block_pin api_map
          # @sg-ignore Need to add nil check here
          node_location = Solargraph::Location.from_node(link.block.node)
          return if node_location.nil?
          block_pins = api_map.get_block_pins
          # @sg-ignore Need to add nil check here
          block_pins.find { |pin| pin.location.contain?(node_location) }
        end
      end
    end
  end
end
