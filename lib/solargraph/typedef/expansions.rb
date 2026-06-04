# frozen_string_literal: true

module Solargraph
  module Typedef
    module Expansions
      autoload :Base,              'solargraph/typedef/expansions/base'
      autoload :GenericParameters, 'solargraph/typedef/expansions/generic_parameters'
      autoload :Self,              'solargraph/typedef/expansions/self'

      def self.expand(api_map, pin, receiver)
        Self.expand(api_map, pin, receiver)
      end
    end
  end
end
