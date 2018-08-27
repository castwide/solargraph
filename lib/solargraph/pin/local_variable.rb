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
        return result if result.defined? or signature.nil?
        # @todo Get the return type from the assignment
        # @todo Instead of parsing a signature, start with an assignment node
        chain = Source::Chain.load_string(signature)
        fragment = api_map.fragment_at(location)
        chain.infer_type_with(api_map, context, fragment.locals)
        # ComplexType::UNDEFINED
      end

      def try_merge! pin
        return false unless super
        @presence = pin.presence
        true
      end
    end
  end
end
