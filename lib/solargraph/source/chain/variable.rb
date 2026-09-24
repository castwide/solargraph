# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class Variable < Link
        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param locals [::Array<Pin::Base>]
        # @param _receiver_path [::Array<String>, nil]
        def resolve api_map, name_pin, locals, _receiver_path = nil
          api_map.get_instance_variable_pins(name_pin.context.namespace, name_pin.context.scope).select do |p|
            p.name == word
          end
        end
      end
    end
  end
end
