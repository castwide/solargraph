# frozen_string_literal: true

module Solargraph
  module Typedef
    module Expansions
      # Contextual expansion of generic parameters from arguments
      #
      class GenericParameters < Base
        def expand
          return pin.typedef_typeset unless pin.typedef_typeset.generic?
          return pin.typedef_typeset unless receiver.parameters.map(&:typedef_typeset).any?(&:generic?)

          pin.typedef_typeset
        end
      end
    end
  end
end
