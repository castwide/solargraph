# frozen_string_literal: true

module Solargraph
  module Pin
    module Localized
      # @return [Range]
      attr_reader :presence

      # @param other [Pin::Base] The caller's block
      # @param position [Position, Array(Integer, Integer)] The caller's position
      # @return [Boolean]
      def visible_from?(other, position)
        position = Position.normalize(position)
        other.filename == filename and
          (other == closure ||
            (closure.location.range.contain?(closure.location.range.start) && closure.location.range.contain?(other.location.range.ending))
          ) &&
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
