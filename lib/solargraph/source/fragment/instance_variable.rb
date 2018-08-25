module Solargraph
  class Source
    class Fragment
      class InstanceVariable < Link
        def resolve api_map, context, locals
          # @todo How is this supposed to work?
          # ComplexType.parse('String').first
          pins = api_map.get_instance_variable_pins(context.namespace, context.scope).select{|p| p.name == word}
          pins.each do |pin|
            type = api_map.infer_pin_type(pin)
            return type unless type.undefined?
          end
          ComplexType::UNDEFINED
        end
      end
    end
  end
end
