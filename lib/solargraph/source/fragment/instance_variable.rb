module Solargraph
  class Source
    class Fragment
      class InstanceVariable < Link
        def resolve_pins api_map, context, locals
          # @todo How is this supposed to work?
          api_map.get_instance_variable_pins(context.namespace, context.scope).select{|p| p.name == word}
        end
      end
    end
  end
end
