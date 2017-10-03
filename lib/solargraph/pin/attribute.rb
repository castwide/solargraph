module Solargraph
  module Pin
    class Attribute < Base
      attr_reader :access

      def initialize source, node, namespace, access
        super(source, node, namespace)
        @access = access
      end

      def name
        @name ||= "#{node.children[0]}#{access == :writer ? '=' : ''}"
      end
    end
  end
end
