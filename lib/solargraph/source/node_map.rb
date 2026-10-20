# frozen_string_literal: true

module Solargraph
  class Source
    class NodeMap
      # @param node [Parser::AST::Node]
      def initialize node
        @node = node
      end

      def find_by_type type
        node_map[type] || []
      end

      private

      def node_map
        @node_map ||= flatten(@node).to_set.classify(&:type)
      end

      def flatten from
        return [] unless from.is_a?(::Parser::AST::Node)
        [from].concat(from.children.flat_map { |child| flatten child })
      end
    end
  end
end
