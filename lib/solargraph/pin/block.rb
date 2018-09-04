module Solargraph
  module Pin
    class Block < Base
      # The signature of the method that receives this block.
      #
      # @return [Parser::AST::Node]
      attr_reader :receiver

      # @return [Array<String>]
      attr_reader :parameters

      attr_reader :scope

      def initialize location, namespace, name, comments, receiver, scope
        super(location, namespace, name, comments)
        @receiver = receiver
        @scope = scope
      end

      def kind
        Pin::BLOCK
      end

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
