module Solargraph
  module Pin
    module Localized
      attr_reader :block
      attr_reader :presence

      def visible_from?(block, position)
        self.block == block and presence.contain?(position)
      end
    end
  end
end
