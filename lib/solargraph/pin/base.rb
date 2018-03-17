module Solargraph
  module Pin
    class Base
      include Conversions

      # @return [Solargraph::Source]
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
        @docstring ||= source.docstring_for(node) unless source.nil?
        @docstring
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

      def arguments
        parameters
      end

      # @return [String]
      def filename
        source.filename unless source.nil?
      end

      def location
        "#{source.filename}:#{node.location.expression.line - 1}:#{node.location.expression.column}" unless source.nil? or node.nil?
      end

      # True if the suggestion has documentation.
      # Useful for determining whether a client should resolve a suggestion's
      # path to retrieve more information about it.
      #
      # @return [Boolean]
      def has_doc?
        !docstring.nil? and !docstring.all.empty?
      end

      def to_s
        name.to_s
      end
    end
  end
end
