# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class InstanceVariable < Link
        # @param word [String]
        # @param node [Parser::AST::Node, nil] The node representing the variable
        # @param location [Location, nil] The location of the variable reference in the source
        def initialize word, node, location
          super(word)
          @node = node
          @location = location
        end

        def resolve api_map, name_pin, locals
          api_map.get_instance_variable_pins(name_pin.context.namespace, name_pin.context.scope).select{|p| p.name == word}
        end

        private

        # @todo: Missed nil violation
        # @return [Location]
        attr_reader :location
      end
    end
  end
end
