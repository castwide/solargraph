# frozen_string_literal: true

module Solargraph
  module Typedef
    module Expansions
      autoload :Base,              'solargraph/typedef/expansions/base'
      autoload :Generics,          'solargraph/typedef/expansions/generics'
      autoload :Self,              'solargraph/typedef/expansions/self'

      def self.expand(api_map, pin, receiver)
        # @todo Just testing
        Self.expand(api_map, pin, receiver)
      end
    end
  end
end
