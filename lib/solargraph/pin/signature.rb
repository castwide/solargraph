module Solargraph
  module Pin
    class Signature
      # @return [Array<Parameter>]
      attr_reader :parameters
      
      # @return [ComplexType]
      attr_reader :return_type

      def initialize parameters, return_type
        @parameters = parameters
        @return_type = return_type
      end
    end
  end
end
