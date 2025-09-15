# frozen_string_literal: true

module Solargraph
  module Pin
    class Keyword < Base
      def initialize(name, **kwargs)
        # @sg-ignore "Unrecognized keyword argument kwargs to Solargraph::Pin::Base#initialize"
        super(name: name, **kwargs)
      end

      def closure
        @closure ||= Pin::ROOT_PIN
      end

      def name
        @name
      end
    end
  end
end
