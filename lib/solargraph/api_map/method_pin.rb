module Solargraph
  class ApiMap
    class MethodPin
      attr_reader :node
      attr_reader :visibility
      def initialize node, visibility
        @node = node
        @visibility = visibility
      end
    end
  end
end
