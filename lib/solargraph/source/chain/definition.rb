module Solargraph
  class Source
    class Chain
      class Definition < Link
        # @param location [Solargraph::Location]
        def initialize location
          @location = location
        end

        # @param api_map [ApiMap]
        def resolve api_map, name_pin, locals
          # api_map.locate_pin(@location)
          [api_map.source_map(@location.filename).locate_named_path_pin(@location.range.start.line, @location.range.start.column)]
        end
      end
    end
  end
end
