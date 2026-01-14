# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class Constant < Link
        def initialize word
          @word = word

          super
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
          # @sg-ignore Need to add nil check here
          fqns = api_map.resolve(base, gates)
          # @sg-ignore Need to add nil check here
          api_map.get_path_pins(fqns)
        end
      end
    end
  end
end
