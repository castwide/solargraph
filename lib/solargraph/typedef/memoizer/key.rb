# frozen_string_literal: true

module Solargraph
  module Typedef
    module Memoizer
      # Unique identifier for memoized values in Memoizer::Cache
      #
      class Key
        # @return [String, nil]
        attr_reader :filename

        # @return [ApiMap, nil]
        attr_reader :api_map

        # @return [Chain, nil]
        attr_reader :chain

        # @return [Symbol]
        attr_reader :action

        # @return [Integer]
        attr_reader :hash

        # @return [Pin::Closure]
        attr_reader :closure

        def initialize filename:, api_map:, chain:, action:, closure:
          @filename = filename
          @api_map = api_map
          @chain = chain
          @action = action
          @closure = closure
          @hash = [filename, api_map, chain, action, closure].hash
          freeze
        end

        def eql? other
          other.instance_of?(Key) &&
            filename == other.filename &&
            api_map == other.api_map &&
            chain == other.chain &&
            action == other.action
        end
      end
    end
  end
end
