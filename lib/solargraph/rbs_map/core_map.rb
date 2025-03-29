# frozen_string_literal: true

module Solargraph
  class RbsMap
    # Ruby core pins
    #
    class CoreMap
      include Conversions

      def initialize
        cache = Cache.load('core.ser')
        if cache
          pins.replace cache
        else
          loader = RBS::EnvironmentLoader.new(repository: RBS::Repository.new(no_stdlib: false))
          RBS::Environment.from_loader(loader).resolve_type_names
          load_environment_to_pins(loader)
          pins.concat RbsMap::CoreFills::ALL
          processed = ApiMap::Store.new(pins).pins.reject { |p| p.is_a?(Solargraph::Pin::Reference::Override) }
          processed.each { |pin| pin.source = :rbs }
          pins.replace processed

          Cache.save('core.ser', pins)
        end
      end
    end
  end
end
