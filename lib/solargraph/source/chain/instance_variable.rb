module Solargraph
  class Source
    class Chain
      class InstanceVariable < Link
        def resolve api_map, context, locals
          api_map.get_instance_variable_pins(context.namespace, context.scope).select{|p| p.name == word}
        end
      end
    end
  end
end
