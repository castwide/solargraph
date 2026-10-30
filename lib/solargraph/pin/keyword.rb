# frozen_string_literal: true

module Solargraph
  module Pin
    class Keyword < Base
      def initialize(name, **kwargs)
        # @sg-ignore https://github.com/apiology/solargraph/pull/429
        #   double-splat checks need https://github.com/apiology/solargraph/tree/kwsplat-record-types on top
        super(name: name, **kwargs)
      end

      def closure
        @closure ||= Pin::ROOT_PIN
      end
    end
  end
end
