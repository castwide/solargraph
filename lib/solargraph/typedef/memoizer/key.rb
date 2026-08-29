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

        # @return [Position, nil]
        attr_reader :position

        # @return [Symbol]
        attr_reader :action

        # @return [Integer]
        attr_reader :hash

        def initialize filename:, api_map:, chain:, position:, action:
          @filename = filename
          @api_map = api_map
          @chain = chain
          @position = position
          @action = action
          @hash = [filename, api_map, chain, position, action].hash
          freeze
        end

        def eql? other
          other.instance_of?(Key) &&
            filename == other.filename &&
            api_map == other.api_map &&
            chain == other.chain &&
            position == other.position &&
            action == other.action
        end
      end
    end
  end
end
