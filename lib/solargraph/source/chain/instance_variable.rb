module Solargraph
  class Source
    class Chain
      class InstanceVariable < Link
        def resolve api_map, name_pin, locals
          if name_pin.kind == Pin::NAMESPACE
            api_map.get_instance_variable_pins(name_pin.path, :class).select{|p| p.name == word}
          else
            api_map.get_instance_variable_pins(name_pin.context.namespace, name_pin.context.scope).select{|p| p.name == word}
          end
        end
      end
    end
  end
end
