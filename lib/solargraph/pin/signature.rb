module Solargraph
  module Pin
    class Signature < Callable
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
