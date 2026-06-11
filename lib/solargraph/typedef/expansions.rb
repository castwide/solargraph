# frozen_string_literal: true

module Solargraph
  module Typedef
    module Expansions
      autoload :Base,              'solargraph/typedef/expansions/base'
      autoload :Generics,          'solargraph/typedef/expansions/generics'
      autoload :Macros,            'solargraph/typedef/expansions/macros'

      def self.expand(api_map, pin, receiver)
        # @todo Just testing
        Self.expand(api_map, pin, receiver)
      end
    end
  end
end
