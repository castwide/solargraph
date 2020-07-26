# frozen_string_literal: true

module Solargraph
  module Convention
    # A convention to expose the YAML api
    #
    class Yaml < Base
      def global api_map
        # @todo Lots of visibility boundaries crossed here. Refactor for cleanliness.
        if api_map.send(:yard_map).required.include?('yaml')
          yaml = api_map.get_path_pins('YAML').first.clone
          yaml.instance_variable_set('@return_type', ComplexType.parse('Module<Psych>'))
          Environ.new(
            requires: ['psych'],
            pins: [yaml]
          )
        else
          super
        end
      end
    end
  end
end
