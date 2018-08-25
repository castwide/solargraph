module Solargraph
  class Source
    class Fragment
      class Variable < Link
        def resolve api_map, context, locals
          # @todo How is this supposed to work?
          # ComplexType.parse('String').first
          pins = api_map.get_instance_variable_pins(context.namespace, context.scope).select{|p| p.name == word}
          pins.each do |pin|
            
          end
          ComplexType::VOID
        end
      end
    end
  end
end
