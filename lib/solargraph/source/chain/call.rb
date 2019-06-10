module Solargraph
  class Source
    class Chain
      class Call < Link
        # @return [String]
        attr_reader :word

        # @return [Array<Chain>]
        attr_reader :arguments

        def initialize word, arguments = []
          @word = word
          @arguments = arguments
        end

        def resolve api_map, name_pin, locals
          found = locals.select{|p| p.name == word}
          return inferred_pins(found, api_map, name_pin.context, locals) unless found.empty?
          pins = api_map.get_method_stack(name_pin.binder.namespace, word, scope: name_pin.binder.scope)
          return [] if pins.empty?
          inferred_pins(pins, api_map, name_pin.context, locals)
        end

        private

        def inferred_pins pins, api_map, context, locals
          result = pins.map do |p|
            if CoreFills::METHODS_RETURNING_SELF.include?(p.path)
              next Solargraph::Pin::Method.new(
                location: p.location,
                closure: p.closure,
                name: p.name,
                comments: "@return [#{context.tag}]",
                scope: p.scope,
                visibility: p.visibility,
                args: p.parameters,
                node: p.node
              )
            end
            if CoreFills::METHODS_RETURNING_SUBTYPES.include?(p.path) && !context.subtypes.empty?
              next Solargraph::Pin::Method.new(
                location: p.location,
                closure: p.closure,
                name: p.name,
                comments: "@return [#{context.subtypes.first.tag}]",
                scope: p.scope,
                visibility: p.visibility,
                args: p.parameters,
                node: p.node
              )
            end
            if CoreFills::METHODS_RETURNING_VALUE_TYPES.include?(p.path) && !context.value_types.empty?
              next Solargraph::Pin::Method.new(
                location: p.location,
                closure: p.closure,
                name: p.name,
                comments: "@return [#{context.value_types.first.tag}]",
                scope: p.scope,
                visibility: p.visibility,
                args: p.parameters,
                node: p.node
              )
            end
            if p.kind == Pin::METHOD && !p.macros.empty?
              result = process_macro(p, api_map, context, locals)
              next result unless result.return_type.undefined?
            elsif !p.directives.empty?
              result = process_directive(p, api_map, context, locals)
              next result unless result.return_type.undefined?
            end
            type = p.typify(api_map)
            type = ComplexType.try_parse(context.namespace) if type.tag == 'self'
            type = p.probe(api_map) if type.undefined?
            next p if p.return_type == type
            p.proxy type
          end
          result
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

        def inner_process_macro pin, macro, api_map, context, locals
          vals = arguments.map{ |c| Pin::ProxyType.anonymous(c.infer(api_map, pin, locals)) }
          txt = macro.tag.text.clone
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
      end
    end
  end
end
