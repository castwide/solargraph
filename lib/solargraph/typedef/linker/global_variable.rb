# frozen_string_literal: true

module Solargraph
  module Typedef
    module Linker
      class GlobalVariable < Base
        def resolve
          api_map.get_global_variable_pins.select { |p| p.name == link.word }
        end
      end
    end
  end
end
