# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class InstanceVariable < Link
        # @param word [String]
        # @param node [Parser::AST::Node, nil] The node representing the variable
        def initialize word, node
          super(word)
          @node = node
        end

        def resolve api_map, name_pin, locals
          api_map.get_instance_variable_pins(name_pin.binder.namespace, name_pin.binder.scope).select{|p| p.name == word}
        end
      end
    end
  end
end
