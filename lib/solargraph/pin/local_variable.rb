module Solargraph
  module Pin
    class LocalVariable < BaseVariable
      include Localized

      # def initialize location, namespace, name, comments, assignment, literal, context, block, presence
      def initialize assignment: nil, literal: nil, presence: nil, **splat
        # super(location, namespace, name, comments, assignment, literal, context)
        super(splat)
        # @block = block
        @assignment = assignment
        @presence = presence
      end

      def kind
        Pin::LOCAL_VARIABLE
      end

      def try_merge! pin
        return false unless super
        @presence = pin.presence
        true
      end
    end
  end
end
