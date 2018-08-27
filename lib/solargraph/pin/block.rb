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

      def return_complex_type
        @return_complex_type ||= Solargraph::ComplexType.parse(namespace)
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
