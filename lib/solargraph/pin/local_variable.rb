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

      def infer api_map
        result = super
        return result unless result.undefined?
        # @todo Get the return type from the assignment
        ComplexType::UNDEFINED
      end

      def try_merge! pin
        return false unless super
        @presence = pin.presence
        true
      end
    end
  end
end
