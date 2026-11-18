# frozen_string_literal: true

module Solargraph
  module Pin
    class Keyword < Base
      def initialize(name, **kwargs)
        # @sg-ignore Need record type support
        super(name: name, **kwargs)
      end

      def closure
        @closure ||= Pin::ROOT_PIN
      end
    end
  end
end
