# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class ClassVariable < Link
        def resolve api_map, name_pin, locals
          out = api_map.get_class_variable_pins(name_pin.context.namespace).select { |p| p.name == word }
          logger.debug do
            "ClassVariable#resolve(word=#{word.inspect}, name_pin=#{name_pin.inspect}, " \
              "name_pin.scope=#{name_pin.scope}, name_pin.context=#{name_pin.context}, " \
              "name_pin.context.namespace=#{name_pin.context.namespace} => #{out}"
          end
          out
        end
      end
    end
  end
end
