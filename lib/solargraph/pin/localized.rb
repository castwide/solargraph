module Solargraph
  module Pin
    module Localized
      attr_reader :block

      # @return [Range]
      attr_reader :presence

      # @param other [Pin::Base] The caller's block
      # @param position [Position, Array(Integer, Integer)] The caller's position
      # @return [Boolean]
      def visible_from?(other, position)
        position = Position.normalize(position)
        other.filename == filename and
          ( other == block or 
            (block.location.range.contain?(other.location.range.start) and block.location.range.contain?(other.location.range.ending))
          ) and
          presence.contain?(position)
      end

      # @param other_loc [Location]
      def visible_at?(other_loc)
        return false if location.filename != other_loc.filename
        presence.include?(other_loc.range.start)
      end
    end
  end
end
