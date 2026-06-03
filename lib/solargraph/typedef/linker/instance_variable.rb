# frozen_string_literal: true

module Solargraph
  module Typedef
    module Linker
      class InstanceVariable < Base
        # @return [Array<Pin::Base>]
        def resolve
          ivars = api_map.get_instance_variable_pins(closure.context.namespace, closure.context.scope).select do |p|
            p.name == link.word
          end
          out = api_map.var_at_location(ivars, link.word, closure, dictionary.location)
          [out].compact
        end
      end
    end
  end
end
