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

        def resolve api_map, context, locals
          found = locals.select{|p| p.name == word}
          return inferred_pins(found, api_map, context) unless found.empty?
          pins = api_map.get_method_stack(context.namespace, word, scope: context.scope)
          return [] if pins.empty?
          pins[0] = virtual_new_pin(pins.first, context) if pins.first.path == 'Class#new'
          inferred_pins(pins, api_map, context)
        end

        private

        # Create a `new` pin to facilitate type inference. This is necessary for
        # classes from YARD and classes in the namespace that do not have an
        # `initialize` method.
        #
        # @param new_pin [Solargraph::Pin::Base]
        # @param context_pin [Solargraph::Pin::Base]
        # @return [Pin::Method]
        def virtual_new_pin new_pin, context
          pin = Pin::Method.new(new_pin.location, context.namespace, new_pin.name, '', :class, new_pin.visibility, new_pin.parameters)
          # @todo Smelly instance variable access.
          pin.instance_variable_set(:@return_complex_type, ComplexType.parse(context.namespace))
          pin
        end

        def inferred_pins pins, api_map, context
          result = pins.map do |p|
            if CoreFills::METHODS_RETURNING_SELF.include?(p.path)
              next Solargraph::Pin::Method.new(p.location, p.namespace, p.name, "@return [#{context.tag}]", p.scope, p.visibility, p.parameters)
            end
            if CoreFills::METHODS_RETURNING_SUBTYPES.include?(p.path) and !context.subtypes.empty?
              next Solargraph::Pin::Method.new(p.location, p.namespace, p.name, "@return [#{context.subtypes.first.tag}]", p.scope, p.visibility, p.parameters)
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
