# frozen_string_literal: true

module Solargraph
  module Typedef
    class Type
      def initialize route:, parameters: []
        @route = route
        @parameters = parameters
      end
    end
  end
end
