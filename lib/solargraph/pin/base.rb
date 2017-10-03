module Solargraph
  module Pin
    class Base
      attr_reader :source
      attr_reader :node
      attr_reader :namespace

      def initialize source, node, namespace
        @source = source
        @node = node
        @namespace = namespace
      end

      def docstring
        @docstring ||= source.docstring_for(node)
      end

      def name
        nil
      end

      def path
        nil
      end

      def kind
        nil
      end

      def return_type
        nil
      end

      def signature
        nil
      end

      def value
        nil
      end

      def parameters
        []
      end
    end
  end
end
