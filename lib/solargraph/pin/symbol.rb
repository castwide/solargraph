module Solargraph
  module Pin
    class Symbol < Base
      def name
        @name ||= ":#{node.children[0]}"
      end
    end
  end
end
