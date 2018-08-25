module Solargraph
  class Source
    class Fragment
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
          return ComplexType.parse(context.namespace).first if word == 'new' and context.scope == :class
          found = locals.select{|p| p.name == word}
          found.each do |pin|
            type = api_map.infer_pin_type(pin)
            return type unless type.void?
          end
          return ComplexType::VOID unless found.empty?
          pins = api_map.get_method_stack(context.namespace, word, scope: context.scope)
          pins.each do |pin|
            # @todo This is where we can handle stuff like core fills and macros!
            return pin.return_complex_type.qualify(api_map, context.namespace) unless pin.return_complex_type.nil?
          end
          ComplexType::VOID
        end
      end
    end
  end
end
