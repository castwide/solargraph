module Solargraph
  module Pin
    class Block < Base
      attr_reader :receiver
      attr_reader :parameters

      def initialize location, namespace, name, docstring, receiver
        super(location, namespace, name, docstring)
        @receiver = receiver
      end

      def kind
        Pin::BLOCK
      end

      def parameters
        @parameters ||= []
      end
    end
  end
end
