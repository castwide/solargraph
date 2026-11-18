# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class ZSuper < Call
        # @return [String]
        attr_reader :word

        # @return [::Array<Chain>]
        attr_reader :arguments

        # @param word [String]
        # @param with_block [Boolean] True if the chain is inside a block
        def initialize word, with_block = false
          super(word, nil, [], with_block)
        end

        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param expression_types [::Array<Pin::ExpressionType>] variables and expression narrowings visible at this point
        def resolve api_map, name_pin, expression_types
          super_pins(api_map, name_pin)
        end
      end
    end
  end
end
