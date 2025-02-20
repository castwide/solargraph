module Solargraph
  module Pin
    class Signature < Base
      # @return [Array<Parameter>]
      attr_reader :parameters

      # @return [ComplexType]
      attr_reader :return_type

      # @return [self]
      attr_reader :block

      # @param parameters [Array<Parameter>]
      # @param return_type [ComplexType]
      # @param block [Signature]
      def initialize parameters, return_type, block = nil
        @parameters = parameters
        @return_type = return_type
        @block = block
      end

      def identity
        @identity ||= "signature#{object_id}"
      end

      def block?
        !!@block
      end
    end
  end
end
