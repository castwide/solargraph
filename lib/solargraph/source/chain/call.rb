# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class Call < Link
        # @return [String]
        attr_reader :word

        # @return [::Array<Chain>]
        attr_reader :arguments

        # @return [Chain, nil]
        attr_reader :block

        # @param word [String]
        # @param arguments [::Array<Chain>]
        # @param block [Chain, nil]
        def initialize word, arguments = [], block = nil
          @word = word
          @arguments = arguments
          @block = block
          fix_block_pass
        end

        def with_block?
          !!@block
        end

        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param locals [::Array<Pin::LocalVariable>]
        def resolve api_map, name_pin, locals
          return super_pins(api_map, name_pin) if word == 'super'
          return yield_pins(api_map, name_pin) if word == 'yield'
          found = if head?
            locals.select { |p| p.name == word }
          else
            []
          end
          return inferred_pins(found, api_map, name_pin.context, locals) unless found.empty?
          # @param [ComplexType::UniqueType]
          pins = name_pin.binder.each_unique_type.flat_map do |context|
            api_map.get_method_stack(context.namespace == '' ? '' : context.tag, word, scope: context.scope)
          end
          return [] if pins.empty?
          inferred_pins(pins, api_map, name_pin.context, locals)
        end

        private

        # @param pins [::Enumerable<Pin::Method>]
        # @param api_map [ApiMap]
        # @param context [ComplexType]
        # @param locals [::Array<Pin::LocalVariable>]
        # @return [::Array<Pin::Base>]
        def inferred_pins pins, api_map, context, locals
          result = pins.map do |p|
            next p unless p.is_a?(Pin::Method)
            overloads = p.signatures
            # next p if overloads.empty?
            type = ComplexType::UNDEFINED
            # start with overloads that require blocks; if we are
            # passing a block, we want to find a signature that will
            # use it.  If we didn't pass a block, the logic below will
            # reject it regardless

            sorted_overloads = overloads.sort { |ol| ol.block? ? -1 : 1 }
            new_signature_pin = nil
            sorted_overloads.each do |ol|
              next unless ol.arity_matches?(arguments, with_block?)
              match = true

              atypes = []
              arguments.each_with_index do |arg, idx|
                param = ol.parameters[idx]
                if param.nil?
                  match = ol.parameters.any?(&:restarg?)
                  break
                end
                atype = atypes[idx] ||= arg.infer(api_map, Pin::ProxyType.anonymous(context), locals)
                # make sure we get types from up the method
                # inheritance chain if we don't have them on this pin
                ptype = param.typify api_map
                # @todo Weak type comparison
                # unless atype.tag == param.return_type.tag || api_map.super_and_sub?(param.return_type.tag, atype.tag)
                unless ptype.undefined? || atype.name == ptype.name || ptype.any? { |current_ptype| api_map.super_and_sub?(current_ptype.name, atype.name) } || ptype.generic? || param.restarg?
                  match = false
                  break
                end
              end
              if match
                if ol.block && with_block?
                  block_atypes = ol.block.parameters.map(&:return_type)
                  blocktype = block_call_type(api_map, context, block_atypes, locals)
                end
                new_signature_pin = ol.resolve_generics_from_context_until_complete(ol.generics, atypes, nil, nil, blocktype)
                new_return_type = new_signature_pin.return_type
                type = with_params(new_return_type.self_to(context.to_s), context).qualify(api_map, context.namespace) if new_return_type.defined?
                type ||= ComplexType::UNDEFINED
              end
              break if type.defined?
            end
            p = p.with_single_signature(new_signature_pin) unless new_signature_pin.nil?
            next p.proxy(type) if type.defined?
            if !p.macros.empty?
              result = process_macro(p, api_map, context, locals)
              next result unless result.return_type.undefined?
            elsif !p.directives.empty?
              result = process_directive(p, api_map, context, locals)
              next result unless result.return_type.undefined?
            end
            p
          end
          result.map do |pin|
            if pin.path == 'Class#new' && context.tag != 'Class'
              pin.proxy(ComplexType.try_parse(context.namespace))
            else
              next pin if pin.return_type.undefined?
              selfy = pin.return_type.self_to(context.tag)
              selfy == pin.return_type ? pin : pin.proxy(selfy)
            end
          end
        end

        # @param pin [Pin::Base]
        # @param api_map [ApiMap]
        # @param context [ComplexType]
        # @param locals [Enumerable<Pin::Base>]
        # @return [Pin::Base]
        def process_macro pin, api_map, context, locals
          pin.macros.each do |macro|
            # @todo 'Wrong argument type for
            #   Solargraph::Source::Chain::Call#inner_process_macro:
            #   macro expected YARD::Tags::MacroDirective, received
            #   generic<Elem>' is because we lose 'rooted' information
            #   in the 'Chain::Array' class internally, leaving
            #   ::Array#each shadowed when it shouldn't be.
            result = inner_process_macro(pin, macro, api_map, context, locals)
            return result unless result.return_type.undefined?
          end
          Pin::ProxyType.anonymous(ComplexType::UNDEFINED)
        end

        # @param pin [Pin::Method]
        # @param api_map [ApiMap]
        # @param context [ComplexType]
        # @param locals [Enumerable<Pin::Base>]
        # @return [Pin::ProxyType]
        def process_directive pin, api_map, context, locals
          pin.directives.each do |dir|
            macro = api_map.named_macro(dir.tag.name)
            next if macro.nil?
            result = inner_process_macro(pin, macro, api_map, context, locals)
            return result unless result.return_type.undefined?
          end
          Pin::ProxyType.anonymous ComplexType::UNDEFINED
        end

        # @param pin [Pin::Base]
        # @param macro [YARD::Tags::MacroDirective]
        # @param api_map [ApiMap]
        # @param context [ComplexType]
        # @param locals [Enumerable<Pin::Base>]
        # @return [Pin::ProxyType]
        def inner_process_macro pin, macro, api_map, context, locals
          vals = arguments.map{ |c| Pin::ProxyType.anonymous(c.infer(api_map, pin, locals)) }
          txt = macro.tag.text.clone
          if txt.empty? && macro.tag.name
            named = api_map.named_macro(macro.tag.name)
            txt = named.tag.text.clone if named
          end
          i = 1
          vals.each do |v|
            txt.gsub!(/\$#{i}/, v.context.namespace)
            i += 1
          end
          docstring = Solargraph::Source.parse_docstring(txt).to_docstring
          tag = docstring.tag(:return)
          unless tag.nil? || tag.types.nil?
            return Pin::ProxyType.anonymous(ComplexType.try_parse(*tag.types))
          end
          Pin::ProxyType.anonymous(ComplexType::UNDEFINED)
        end

        # @param docstring [YARD::Docstring]
        # @param context [ComplexType]
        # @return [ComplexType, nil]
        def extra_return_type docstring, context
          if docstring.has_tag?('return_single_parameter') #&& context.subtypes.one?
            return context.subtypes.first || ComplexType::UNDEFINED
          elsif docstring.has_tag?('return_value_parameter') && context.value_types.one?
            return context.value_types.first
          end
          nil
        end

        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @return [::Array<Pin::Base>]
        def super_pins api_map, name_pin
          pins = api_map.get_method_stack(name_pin.namespace, name_pin.name, scope: name_pin.context.scope)
          pins.reject{|p| p.path == name_pin.path}
        end

        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @return [::Array<Pin::Base>]
        def yield_pins api_map, name_pin
          method_pin = api_map.get_method_stack(name_pin.namespace, name_pin.name, scope: name_pin.context.scope).first
          return [] if method_pin.nil?

          method_pin.signatures.map(&:block).compact
        end

        # @param type [ComplexType]
        # @param context [ComplexType]
        # @return [ComplexType]
        def with_params type, context
          return type unless type.to_s.include?('$')
          ComplexType.try_parse(type.to_s.gsub('$', context.value_types.map(&:tag).join(', ')).gsub('<>', ''))
        end

        # @return [void]
        def fix_block_pass
          argument = @arguments.last&.links&.first
          @block = @arguments.pop if argument.is_a?(BlockSymbol) || argument.is_a?(BlockVariable)
        end

        # @param api_map [ApiMap]
        # @param context [ComplexType]
        # @param block_parameter_types [::Array<ComplexType>]
        # @param locals [::Array<Pin::LocalVariable>]
        # @return [ComplexType, nil]
        def block_call_type(api_map, context, block_parameter_types, locals)
          return nil unless with_block?

          # @todo Handle BlockVariable
          if block.links.map(&:class) == [BlockSymbol]
            # Ruby's shorthand for sending the passed in method name
            # to the first yield parameter with no arguments
            block_symbol_name = block.links.first.word
            block_symbol_call_path = "#{block_parameter_types.first}##{block_symbol_name}"
            callee = api_map.get_path_pins(block_symbol_call_path).first
            return_type = callee&.return_type
            # @todo: Figure out why we get unresolved generics at
            #   this point and need to assume method return types
            #   based on the generic type
            return_type ||= api_map.get_path_pins("#{context.subtypes.first}##{block.links.first.word}").first&.return_type
            return_type || ComplexType::UNDEFINED
          else
            block.infer(api_map, Pin::ProxyType.anonymous(context), locals)
          end
        end
      end
    end
  end
end
