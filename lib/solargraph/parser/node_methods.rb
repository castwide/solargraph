module Solargraph
  module Parser
    class NodeMethods
      module_function

      # @param node [Parser::AST::Node]
      # @return [String]
      def unpack_name node
        raise NotImplementedError
      end

      def infer_literal_type node
        raise NotImplementedError
      end

      def calls_from node
        raise NotImplementedError
      end

      # @param node [Parser::AST::Node]
      # @return [Array<Parser::AST::Node>]
      def returns_from node
        raise NotImplementedError
      end

      # @param node [Parser::AST::Node]
      # @return [void]
      def process node
        raise NotImplementedError
      end

      def references node
        raise NotImplementedError
      end

      # @param node [Parser::AST::Node]
      # @param filename [String, nil]
      # @param in_block [Boolean]
      # @return [Source::Chain]
      def chain node, filename = nil, in_block = false
        raise NotImplementedError
      end

      # @param node [Parser::AST::Node]
      def node? node
        raise NotImplementedError
      end

      # @param node [Parser::AST::Node]
      # @return [Hash{Parser::AST::Node => Chain}]
      def convert_hash node
        raise NotImplementedError
      end
    end
  end
end
