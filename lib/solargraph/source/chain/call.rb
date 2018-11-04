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
          pins = api_map.get_method_stack(name_pin.context.namespace, word, scope: name_pin.context.scope)
          return [] if pins.empty?
          pins.unshift virtual_new_pin(pins.first, name_pin.context) if external_constructor?(pins.first, name_pin.context)
          inferred_pins(pins, api_map, name_pin.context, locals)
        end

        private

        # Create a `new` pin to facilitate type inference. This is necessary for
        # classes from YARD and classes in the namespace that do not have an
        # `initialize` method.
        #
        # @param new_pin [Solargraph::Pin::Base]
        # @param context [Solargraph::ComplexType]
        # @return [Pin::Method]
        def virtual_new_pin new_pin, context
          # pin = Pin::Method.new(new_pin.location, context.namespace, new_pin.name, '', :class, new_pin.visibility, new_pin.parameters)
          # @todo Smelly instance variable access.
          # pin.instance_variable_set(:@return_complex_type, ComplexType.parse(context.namespace))
          # pin
          Pin::ProxyType.anonymous(ComplexType.parse(context.namespace))
        end

        def inferred_pins pins, api_map, context, locals
          result = pins.map do |p|
            if CoreFills::METHODS_RETURNING_SELF.include?(p.path)
              next Solargraph::Pin::Method.new(p.location, p.namespace, p.name, "@return [#{context.tag}]", p.scope, p.visibility, p.parameters)
            end
            if CoreFills::METHODS_RETURNING_SUBTYPES.include?(p.path) && !context.subtypes.empty?
              next Solargraph::Pin::Method.new(p.location, p.namespace, p.name, "@return [#{context.subtypes.first.tag}]", p.scope, p.visibility, p.parameters)
            end
            if p.kind == Pin::METHOD && !p.macros.empty?
              result = process_macro(p, api_map, context, locals)
              next result unless result.return_type.undefined?
            elsif !p.directives.empty?
              result = process_directive(p, api_map, context, locals)
              next result unless result.return_type.undefined?
            end
            next p if p.kind == Pin::METHOD || p.kind == Pin::ATTRIBUTE || p.kind == Pin::NAMESPACE
            type = p.infer(api_map)
            next p if p.return_complex_type == type
            Pin::ProxyType.new(p.location, nil, p.name, type)
          end
          result
        end

        def external_constructor? pin, context
          pin.path == 'Class#new' || (pin.name == 'new' && pin.scope == :class && pin.return_type != context)
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
          Pin::ProxyType.new(nil, nil, nil, ComplexType::UNDEFINED)
        end

        def process_directive pin, api_map, context, locals
          pin.directives.each do |dir|
            macro = api_map.named_macro(dir.tag.name)
            next if macro.nil?
            result = inner_process_macro(pin, macro, api_map, context, locals)
            return result unless result.return_type.undefined?
          end
          Pin::ProxyType.new(nil, nil, nil, ComplexType::UNDEFINED)
        end

        def inner_process_macro pin, macro, api_map, context, locals
          vals = arguments.map{ |c| Pin::ProxyType.anonymous(c.infer(api_map, pin, locals)) }
          txt = macro.tag.text.clone
          i = 1
          vals.each do |v|
            txt.gsub!(/\$#{i}/, v.context.namespace)
            i += 1
          end
          docstring = YARD::Docstring.parser.parse(txt).to_docstring
          tag = docstring.tag(:return)
          unless tag.nil? || tag.types.nil?
            return Pin::ProxyType.anonymous(ComplexType.parse(*tag.types))
          end
          Pin::ProxyType.new(nil, nil, nil, ComplexType::UNDEFINED)
        end
      end
    end
  end
end
