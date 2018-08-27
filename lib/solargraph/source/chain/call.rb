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
          return [instance_pin(context)] if word == 'new' and context.scope == :class
          found = locals.select{|p| p.name == word}
          return found unless found.empty?
          api_map.get_method_stack(context.return_complex_type.namespace, word, scope: context.scope)
        end

        def instance_pin context
          STDERR.puts "The instance created is #{context.return_complex_type.namespace}"
          Pin::ProxyType.new(nil, context.namespace, context.name, ComplexType.parse(context.return_complex_type.namespace))
        end
      end
    end
  end
end
