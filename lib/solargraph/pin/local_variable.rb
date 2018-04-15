module Solargraph
  module Pin
    class LocalVariable < BaseVariable
      include Localized

      def initialize location, namespace, name, docstring, assignment, literal, context, block, presence
        super(location, namespace, name, docstring, assignment, literal, context)
        @block = block
        @presence = presence
      end

      def kind
        Pin::LOCAL_VARIABLE
      end
    end
  end
end
