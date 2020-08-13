# frozen_string_literal: true

module Solargraph
  module Convention
    # A convention to expose the YAML api
    #
    class Core < Base
      def global api_map
        Environ.new(
          pins: CoreFills::ALL
        )
      end
    end
  end
end
