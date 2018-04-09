module Solargraph
  class Tracer
    class Issue
      # The severity of the issue. An issue is considered an error when the
      # value returned from a method does not match the type in the method's
      # `@return` tag. Most other issues are considered warnings.
      #
      # @return [Symbol] :warning or :error
      attr_reader :severity

      # A human-readable description of the issue.
      #
      # @return [String]
      attr_reader :message

      # The name of the method that had the issue.
      #
      # @return [String]
      attr_reader :method_name

      # The method's pin.
      #
      # @return [Solargraph::Pin::Method]
      attr_reader :pin

      # The stack of callers at the moment the issue was logged.
      #
      # @return [Array<String>]
      attr_reader :backtrace

      def initialize severity, message, method_name, pin, backtrace
        @severity = severity
        @message = message
        @method_name = method_name.to_s
        @pin = pin
        @backtrace = backtrace
      end

      def to_s
        message
      end
    end
  end
end
