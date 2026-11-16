# frozen_string_literal: true

module Solargraph
  module Typedef
    module Memoizer
      # Unique identifier for memoized values in Memoizer::Cache
      #
      class Key
        include Equality

        attr_reader :api_map, :filename, :detail

        # @param api_map [ApiMap]
        # @param filename [String, nil]
        # @param detail [Hash]
        def initialize api_map, filename, detail
          @api_map = api_map
          @filename = filename
          @detail = detail
        end

        def equality_fields
          [api_map, filename, detail]
        end
      end
    end
  end
end
