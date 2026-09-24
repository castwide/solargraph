# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class Constant < Link
        def initialize word
          @word = word

          super
        end

        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param locals [::Array<Pin::Base>]
        # @param _receiver_path [::Array<String>, nil]
        def resolve api_map, name_pin, locals, _receiver_path = nil
          return [Pin::ROOT_PIN] if word.empty?
          if word.start_with?('::')
            base = word[2..]
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
