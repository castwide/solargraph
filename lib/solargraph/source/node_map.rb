# frozen_string_literal: true

module Solargraph
  class Source
    class NodeMap
      # @param node [Parser::AST::Node, nil]
      def initialize node
        @node = node
      end

      # @param type [Symbol]
      # @return [Set<Parser::AST::Node>, Array<Parser::AST::Node>]
      def find_by_type type
        node_map[type] || []
      end

      private

      # @return [Hash{Symbol => Set<Parser::AST::Node>}]
      def node_map
        @node_map ||= flatten(@node).to_set.classify(&:type)
      end

      # @param from [Object]
      # @return [Array<Parser::AST::Node>]
      def flatten from
        return [] unless from.is_a?(::Parser::AST::Node)
        # @sg-ignore https://github.com/castwide/solargraph/pull/1259
        [from].concat(from.children.flat_map { |child| flatten child })
      end
    end
  end
end
