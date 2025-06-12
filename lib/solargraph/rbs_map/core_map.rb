# frozen_string_literal: true

module Solargraph
  class RbsMap
    # Ruby core pins
    #
    class CoreMap
      include Conversions

      def resolved?
        true
      end

      def initialize
      end

      def pins
        return @pins if @pins

        @pins = []
        cache = PinCache.deserialize_core
        if cache
          @pins.replace cache
        else
          RBS::Environment.from_loader(loader).resolve_type_names
          load_environment_to_pins(loader)
          @pins.concat RbsMap::CoreFills::ALL
          processed = ApiMap::Store.new(@pins).pins.reject { |p| p.is_a?(Solargraph::Pin::Reference::Override) }
          processed.each { |pin| pin.source = :rbs }
          @pins.replace processed

          PinCache.serialize_core @pins
        end
        @pins
      end

      def loader
        @loader ||= RBS::EnvironmentLoader.new(repository: RBS::Repository.new(no_stdlib: false))
      end
    end
  end
end
