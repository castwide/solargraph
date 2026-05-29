# frozen_string_literal: true

module Solargraph
  module Typedef
    module Linker
      class Constant < Base
        # @return [Array<Pin::Base>]
        def resolve
          return [Pin::ROOT_PIN] if link.word.empty?
          base = link.word
          gates = closure.gates
          fqns = if base.start_with?('::')
            api_map.resolve(base, '')
          else
            api_map.resolve(base, *gates)
          end
          api_map.get_path_pins(fqns)
        end
      end
    end
  end
end
