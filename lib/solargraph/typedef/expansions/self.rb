# frozen_string_literal: true

module Solargraph
  module Typedef
    module Expansions
      # Contextual expansion of self types
      #
      class Self < Base
        def expand
          pin.typedef_typeset.expand({ 'self' => receiver.namespace })
        end
      end
    end
  end
end
