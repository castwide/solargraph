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

        def resolve_pins api_map, context, locals
          return [self_pin(api_map, context)] if word == 'self'
          found = locals.select{|p| p.name == word}
          return inferred_pins(found, api_map, context) unless found.empty?
          pins = api_map.get_method_stack(namespace_from_context(context), word, scope: context.scope)
          ns = api_map.qualify(word, context.named_context)
          pins.concat api_map.get_path_suggestions(ns) unless ns.nil?
          return [] if pins.empty?
          pins[0] = virtual_new_pin(pins.first, context) if pins.first.path == 'Class#new'
          inferred_pins(pins, api_map, context)
        end

        private

        # @param pin [Pin::Base]
        # @return [String]
        def namespace_from_context pin
          return pin.namespace if pin.kind == Pin::ATTRIBUTE or pin.kind == Pin::METHOD
          pin.return_complex_type.namespace
        end

        # Create a `new` pin to facilitate type inference. This is necessary for
        # classes from YARD and classes in the namespace that do not have an
        # `initialize` method.
        #
        # @param new_pin [Solargraph::Pin::Base]
        # @param context_pin [Solargraph::Pin::Base]
        # @return [Pin::Method]
        def virtual_new_pin new_pin, context_pin
          pin = Pin::Method.new(new_pin.location, context_pin.path, new_pin.name, '', :class, new_pin.visibility, new_pin.parameters)
          # @todo Smelly instance variable access.
          pin.instance_variable_set(:@return_complex_type, ComplexType.parse(context_pin.path))
          pin
        end

        def self_pin(api_map, context)
          return Pin::ProxyType.anonymous(ComplexType.parse(context.namespace)) if context.scope == :instance
          # return api_map.get_path_suggestions(context.namespace)
          context
        end

        def inferred_pins pins, api_map, context_pin
          result = pins.uniq(&:location).map do |p|
            if CoreFills::METHODS_RETURNING_SELF.include?(p.path)
              next Solargraph::Pin::Method.new(p.location, p.namespace, p.name, "@return [#{context_pin.return_complex_type.tag}]", p.scope, p.visibility, p.parameters)
            end
            if CoreFills::METHODS_RETURNING_SUBTYPES.include?(p.path) and !context_pin.return_complex_type.subtypes.empty?
              next Solargraph::Pin::Method.new(p.location, p.namespace, p.name, "@return [#{context_pin.return_complex_type.subtypes.first.tag}]", p.scope, p.visibility, p.parameters)
            end
            next p if p.kind == Pin::METHOD or p.kind == Pin::ATTRIBUTE or p.kind == Pin::NAMESPACE
            type = p.infer(api_map)
            next p if p.return_complex_type == type
            Pin::ProxyType.new(p.location, nil, p.name, type)
          end
          result
        end
      end
    end
  end
end
