module Solargraph
  module Pin
    class Block < Base
      # The signature of the method that receives this block.
      #
      # @return [String]
      attr_reader :receiver

      # @return [Array<String>]
      attr_reader :parameters

      def initialize location, namespace, name, comments, receiver
        super(location, namespace, name, comments)
        @receiver = receiver
      end

      def kind
        Pin::BLOCK
      end

      def parameters
        @parameters ||= []
      end

      def nearly? other
        return false unless super
        receiver == other.receiver and parameters == other.parameters
      end
    end
  end
end
