module Solargraph
  class Source
    class Chain
      class Call < Link
        # @return [String]
        attr_reader :word

        # @return [Array<Chain>]
        attr_reader :arguments

        # @param word [String]
        # @param arguments [Array<Chain>]
        def initialize word, arguments = []
          @word = word
          @arguments = arguments
        end

        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param locals [Array<Pin::Base>]
        def resolve api_map, name_pin, locals
          found = locals.select{|p| p.name == word}
          return inferred_pins(found, api_map, name_pin.context, locals) unless found.empty?
          pins = api_map.get_method_stack(name_pin.binder.namespace, word, scope: name_pin.binder.scope)
          return [] if pins.empty?
          inferred_pins(pins, api_map, name_pin.context, locals)
        end

        private

        # @param pins [Array<Pin::Base>]
        # @param api_map [ApiMap]
        # @param context [ComplexType]
        # @param locals [Pin::LocalVariable]
        # @return [Array<Pin::Base>]
        def inferred_pins pins, api_map, context, locals
          result = pins.map do |p|
            overloads = p.docstring.tags(:overload)
            # next p if overloads.empty?
            type = ComplexType::UNDEFINED
            # @param [YARD::Tags::OverloadTag]
            overloads.each do |ol|
              next if arguments.length < ol.parameters.length &&
                !(arguments.length == ol.parameters.length - 1 && ol.parameters.last.first.start_with?('*'))
              match = true
              arguments.each_with_index do |arg, idx|
                achain = arguments[idx]
                next if achain.nil?
                param = ol.parameters[idx]
                if param.nil?
                  match = false unless ol.parameters.last && ol.parameters.last.first.start_with?('*')
                  break
                end
                par = ol.tags(:param).select { |pp| pp.name == param.first }.first
                next if par.nil? || par.types.nil? || par.types.empty?
                atype = achain.infer(api_map, Pin::ProxyType.anonymous(context), locals)
                other = ComplexType.try_parse(*par.types)
                # @todo Weak type comparison
                unless atype.tag == other.tag || api_map.super_and_sub?(other.tag, atype.tag)
                  match = false
                  break
                end
              end
              if match
                type = extra_return_type(ol, context)
                type = ComplexType.try_parse(*ol.tag(:return).types).self_to(context.to_s).qualify(api_map, context.namespace) if ol.has_tag?(:return) && ol.tag(:return).types && !ol.tag(:return).types.empty? && (type.nil? || type.undefined?)
                type ||= ComplexType::UNDEFINED
              end
              break if type.defined?
            end
            next p.proxy(type) if type.defined?
            type = extra_return_type(p.docstring, context)
            if type
              next Solargraph::Pin::Method.new(
                location: p.location,
                closure: p.closure,
                name: p.name,
                comments: "@return [#{context.subtypes.first.to_s}]",
                scope: p.scope,
                visibility: p.visibility,
                args: p.parameters,
                node: p.node
              )
            end
            if p.is_a?(Pin::Method) && !p.macros.empty?
              result = process_macro(p, api_map, context, locals)
              next result unless result.return_type.undefined?
            elsif !p.directives.empty?
              result = process_directive(p, api_map, context, locals)
              next result unless result.return_type.undefined?
            end
            p
          end
          result.map do |pin|
            next pin if pin.return_type.undefined?
            selfy = pin.return_type.self_to(context.namespace)
            selfy == pin.return_type ? pin : pin.proxy(selfy)
          end
        end

        # @param pin [Pin::Method]
        # @param api_map [ApiMap]
        # @param context [ComplexType]
        # @return [Pin::Base]
        def process_macro pin, api_map, context, locals
          pin.macros.each do |macro|
            result = inner_process_macro(pin, macro, api_map, context, locals)
            return result unless result.return_type.undefined?
          end
          Pin::ProxyType.anonymous(ComplexType::UNDEFINED)
        end

        def process_directive pin, api_map, context, locals
          pin.directives.each do |dir|
            macro = api_map.named_macro(dir.tag.name)
            next if macro.nil?
            result = inner_process_macro(pin, macro, api_map, context, locals)
            return result unless result.return_type.undefined?
          end
          Pin::ProxyType.anonymous ComplexType::UNDEFINED
        end

        # @param api_map [ApiMap]
        # @param macro [YARD::Tags::MacroDirective]
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
        def extra_return_type docstring, context
          if docstring.has_tag?(:return_single_parameter) && context.subtypes.one?
            return context.subtypes.first
          elsif docstring.has_tag?(:return_value_parameter) && context.value_types.one?
            return context.value_types.first
          # elsif docstring.has_tag?(:return) && docstring.tag(:return).types && !docstring.tag(:return).types.empty?
          #   return ComplexType.try_parse(*docstring.tag(:return).types)
          end
          nil
        end
      end
    end
  end
end
