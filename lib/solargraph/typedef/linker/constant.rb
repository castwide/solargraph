# frozen_string_literal: true

module Solargraph
  module Typedef
    module Linker
      class Constant < Base
        # @return [Array<Pin::Base>]
        def resolve
          return [Pin::ROOT_PIN] if link.word.empty?
          base = link.word
          if base.start_with?('::')
            api_map.get_path_pins(base[2..])
          else
            gates = receiver.gates
            fqns = api_map.resolve(base, *gates)
            api_map.get_path_pins(fqns)
          end
        end
      end
    end
  end
end
