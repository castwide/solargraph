module Solargraph
  module Pin
    class Signature < Callable
      # allow signature to be created before method pin, then set this
      # to the method pin
      attr_writer :closure

      def initialize **splat
        super(**splat)
      end

      def generics
        @generics ||= [].freeze
      end

      def identity
        @identity ||= "signature#{object_id}"
      end
    end
  end
end
