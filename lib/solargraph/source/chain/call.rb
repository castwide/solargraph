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
          return [instance_pin(context)] if word == 'new' and context.scope == :class
          found = locals.select{|p| p.name == word}
          return found unless found.empty?
          api_map.get_method_stack(context.return_complex_type.namespace, word, scope: context.scope)
        end

        private

        def instance_pin context
          Pin::ProxyType.new(nil, context.namespace, context.name, ComplexType.parse(context.return_complex_type.namespace))
        end

        def self_pin(api_map, context)
          return Pin::ProxyType.anonymous(ComplexType.parse(context.namespace)) if context.scope == :instance
          # return api_map.get_path_suggestions(context.namespace)
          context
        end
      end
    end
  end
end
