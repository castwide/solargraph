module Solargraph
  module Pin
    module Localized
      attr_reader :block

      # @return [Source::Range]
      attr_reader :presence

      # @param other [Pin::Block] The caller's block
      # @param position [Source::Position] The caller's position
      # @return [Boolean]
      def visible_from?(other, position)
        other.filename == filename and
          (other == block or other.named_context == named_context) and
          presence.contain?(position)
      end
    end
  end
end
