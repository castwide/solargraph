module Solargraph
  module Pin
    class Block < Base
      # The signature of the method that receives this block.
      #
      # @return [Parser::AST::Node]
      attr_reader :receiver

      def initialize location, namespace, name, comments, receiver, context
        super(location, namespace, name, comments)
        @receiver = receiver
        @context = context
      end

      def kind
        Pin::BLOCK
      end

      # @return [Array<String>]
      def parameters
        @parameters ||= []
      end

      def nearly? other
        return false unless super
        # @todo Trying to not to block merges too much
        # receiver == other.receiver and parameters == other.parameters
        true
      end
    end
  end
end
