module Solargraph
  class TypeChecker
    # A problem reported by TypeChecker.
    #
    class Problem
      # @return [Solargraph::Location]
      attr_reader :location

      # @return [String]
      attr_reader :message

      # @return [String, nil]
      attr_reader :suggestion

      # @param location [Solargraph::Location]
      # @param message [String]
      # @param suggestion [String, nil]
      def initialize location, message, suggestion = nil
        @location = location
        @message = message
        @suggestion = suggestion
      end
    end
  end
end
