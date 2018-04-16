module Solargraph
  module Pin
    module Localized
      attr_reader :block
      attr_reader :presence

      def visible_from?(block, position)
        in_context?(block) and presence.contain?(position)
      end

      private

      def in_context?(other)
        return false if other.filename != filename
        other == block or other.named_context == named_context
      end
    end
  end
end
