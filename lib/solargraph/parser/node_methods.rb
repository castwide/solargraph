module Solargraph
  module Parser
    class NodeMethods
      module_function

      # @abstract
      # @param node [Parser::AST::Node]
      # @return [String]
      def unpack_name node
        raise NotImplementedError
      end

      # @abstract
      # @todo Temporarily here for testing. Move to Solargraph::Parser.
      # @param node [Parser::AST::Node]
      # @return [Array<Parser::AST::Node>]
      def call_nodes_from node
        raise NotImplementedError
      end

      # Find all the nodes within the provided node that potentially return a
      # value.
      #
      # The node parameter typically represents a method's logic, e.g., the
      # second child (after the :args node) of a :def node. A simple one-line
      # method would typically return itself, while a node with conditions
      # would return the resulting node from each conditional branch. Nodes
      # that follow a :return node are assumed to be unreachable. Nil values
      # are converted to nil node types.
      #
      # @abstract
      # @param node [Parser::AST::Node]
      # @return [Array<Parser::AST::Node>]
      def returns_from_method_body node
        raise NotImplementedError
      end

      # @abstract
      # @param node [Parser::AST::Node]
      #
      # @return [Array<Parser::AST::Node>]
      def const_nodes_from node
        raise NotImplementedError
      end

      # @abstract
      # @param cursor [Solargraph::Source::Cursor]
      # @return [Parser::AST::Node, nil]
      def find_recipient_node cursor
        raise NotImplementedError
      end

      # @abstract
      # @param node [Parser::AST::Node]
      # @return [Array<AST::Node>] low-level value nodes in
      #   value position.  Does not include explicit return
      #   statements
      def value_position_nodes_only(node)
        raise NotImplementedError
      end

      # @abstract
      # @param nodes [Enumerable<Parser::AST::Node>]
      def any_splatted_call?(nodes)
        raise NotImplementedError
      end

      # @abstract
      # @param node [Parser::AST::Node]
      # @return [void]
      def process node
        raise NotImplementedError
      end

      # @abstract
      # @param node [Parser::AST::Node]
      # @return [Hash{Parser::AST::Node => Chain}]
      def convert_hash node
        raise NotImplementedError
      end
    end
  end
end
