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
          nearby = dictionary.source_map
                             .pins_by_class(Pin::InstanceVariable)
                             .select { |p| p.name == link.word }
                             .select { |p| dictionary.closure.location.contain?(p.location) }
                             .select { |p| p.location.range.start.line <= dictionary.location.range.start.line }
                             .last
          [nearby || ivars.first]
        end
      end
    end
  end
end
