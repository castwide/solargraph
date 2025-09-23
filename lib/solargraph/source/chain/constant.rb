# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class Constant < Link
        def initialize word
          @word = word
        end

        def resolve api_map, name_pin, locals
          return [Pin::ROOT_PIN] if word.empty?
          if word.start_with?('::')
            base = word[2..-1]
            gates = ['']
          else
            base = word
            gates = name_pin.gates
          end
          fqns = api_map.resolve(base, gates)
          api_map.get_path_pins(fqns)
        end
      end
    end
  end
end
