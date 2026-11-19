# frozen_string_literal: true

module Solargraph
  module Typedef
    module Memoizer
      # A memoized value stored in Memoizer::Cache
      class Memo
        # @return [Typeset, Array(Array<Pin::Base>, Pin::Closure)]
        attr_reader :value

        # @return [Array<String>]
        attr_reader :stack

        # @param value [Typeset, Array(Array<Pin::Base>, Pin::Closure)] The memoized value
        # @param stack [Array<String>] The files processed for this memo
        def initialize value, stack
          @value = value
          @stack = stack
        end
      end
    end
  end
end
