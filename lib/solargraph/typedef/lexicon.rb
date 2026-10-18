# frozen_string_literal: true

module Solargraph
  module Typedef
    class Lexicon
      attr_reader :pin, :context

      # @param pin [Pin::Base]
      # @param context [Typeset]
      def initialize pin, context
        @pin = pin
        @context = context
      end
    end
  end
end
