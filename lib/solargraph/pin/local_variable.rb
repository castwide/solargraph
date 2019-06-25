module Solargraph
  module Pin
    class LocalVariable < BaseVariable
      include Localized

      def initialize assignment: nil, presence: nil, **splat
        super(splat)
        @assignment = assignment
        @presence = presence
      end

      def try_merge! pin
        return false unless super
        @presence = pin.presence
        true
      end
    end
  end
end
