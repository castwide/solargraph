module Solargraph
  module Pin
    class Base
      # @return [Solargraph::ApiMap::Source]
      attr_reader :source

      # @return [Parser::AST::Node]
      attr_reader :node

      # @return [String]
      attr_reader :namespace

      def initialize source, node, namespace
        @source = source
        @node = node
        @namespace = namespace
      end

      # @return [YARD::Docstring]
      def docstring
        @docstring ||= source.docstring_for(node)
      end

      # @return [String]
      def name
        nil
      end

      # @return [String]
      def path
        nil
      end

      # @return [String]
      def kind
        nil
      end

      # @return [String]
      def return_type
        nil
      end

      # @return [String]
      def signature
        nil
      end

      # @return [String]
      def value
        nil
      end

      # @return [Array<String>]
      def parameters
        []
      end

      # @return [String]
      def filename
        source.filename
      end

      def location
        "#{source.filename}:#{node.location.expression.begin_pos}"
      end
    end
  end
end
