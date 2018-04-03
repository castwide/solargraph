module Solargraph
  class ApiMap
    class Completion
      # @return [Array<Solargraph::Pin::Base>]
      attr_reader :pins

      # @return [Solargraph::Source::Range]
      attr_reader :range

      def initialize pins, range
        @pins = pins
        @range = range
      end
    end
  end
end
