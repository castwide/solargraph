module Solargraph
  class Source
    class Fragment
      class ClassVariable < Link
        def resolve_pins api_map, context, locals
          # @todo How is this supposed to work?
          api_map.get_class_variable_pins(context.namespace).select{|p| p.name == word}
        end
      end
    end
  end
end
