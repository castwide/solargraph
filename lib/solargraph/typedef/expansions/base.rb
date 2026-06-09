# frozen_string_literal: true

module Solargraph
  module Typedef
    module Expansions
      # Contextual expansion of self types
      #
      class Base
        # @return [ApiMap]
        attr_reader :api_map

        # @return [Pin::Base]
        attr_reader :pin

        # @return [Pin::Closure]
        attr_reader :receiver

        # @param api_map [ApiMap]
        # @param pin [Pin::Base]
        # @param receiver [Pin::Closure]
        def initialize api_map, pin, receiver
          @api_map = api_map
          @pin = pin
          @receiver = receiver
        end

        # @return [Typeset]
        def expand
          raise 'Not implemented'
        end
        
        def self.expand api_map, pin, receiver
          new(api_map, pin, receiver).expand
        end
      end
    end
  end
end
