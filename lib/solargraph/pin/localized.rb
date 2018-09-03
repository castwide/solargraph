module Solargraph
  module Pin
    module Localized
      attr_reader :block

      # @return [Range]
      attr_reader :presence

      # @param other [Pin::Base] The caller's block
      # @param position [Position] The caller's position
      # @return [Boolean]
      def visible_from?(other, position)
        other.filename == filename and
          (other == block or other.context == context) and
          presence.contain?(position)
      end
    end
  end
end
