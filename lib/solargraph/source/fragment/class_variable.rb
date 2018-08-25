module Solargraph
  class Source
    class Fragment
      class ClassVariable < Link
        def resolve api_map, context, locals
          # @todo How is this supposed to work?
          # ComplexType.parse('String').first
          pins = api_map.get_class_variable_pins(context.namespace).select{|p| p.name == word}
          pins.each do |pin|
            type = api_map.infer_pin_type(pin)
            return type unless type.void?
          end
          ComplexType::UNDEFINED
        end
      end
    end
  end
end
