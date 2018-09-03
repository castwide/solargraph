module Solargraph
  class SourceMap
    class Chain
      class Definition < Link
        # @param location [Solargraph::Location]
        def initialize location
          @location = location
        end

        def resolve api_map, name_pin, locals
          api_map.locate_pin(@location)
        end
      end
    end
  end
end
