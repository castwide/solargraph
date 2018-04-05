module Solargraph
  class Tracer
    class Issue
      # @return [Symbol] :warning or :error
      attr_reader :severity

      # @return [String]
      attr_reader :message

      # @return [String]
      attr_reader :method_name

      # @return [String]
      attr_reader :expected

      # @return [String]
      attr_reader :actual

      # @return [Array<String>]
      attr_reader :backtrace

      def initialize severity, message, method_name, expected, actual, backtrace
        @severity = severity
        @message = message
        @method_name = method_name.to_s
        @backtrace = backtrace
      end

      def to_s
        message
      end
    end
  end
end
