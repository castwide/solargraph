# frozen_string_literal: true

module Solargraph
  module Typedef
    class Memo
      attr_reader :value

      attr_reader :stack

      def initialize value, stack
        @value = value
        @stack = stack
      end
    end
  end
end
