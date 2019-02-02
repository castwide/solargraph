module Solargraph
  module Pin
    class LocalVariable < BaseVariable
      include Localized

      def initialize location, namespace, name, comments, assignment, literal, context, block, presence
        super(location, namespace, name, comments, assignment, literal, context)
        @block = block
        @presence = presence
      end

      def kind
        Pin::LOCAL_VARIABLE
      end

      # @param other_loc [Location]
      def visible_at?(other_loc)
        return false if location.filename != other_loc.filename
        presence.include?(other_loc.range.start)
      end

      def try_merge! pin
        return false unless super
        @presence = pin.presence
        true
      end
    end
  end
end
