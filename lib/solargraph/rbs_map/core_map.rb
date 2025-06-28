# frozen_string_literal: true

module Solargraph
  class RbsMap
    # Ruby core pins
    #
    class CoreMap

      FILLS_DIRECTORY = File.join(File.dirname(__FILE__), '..', '..', '..', 'rbs', 'fills')

      def initialize
        cache = Cache.load('core.ser')
        if cache
          pins.replace cache
        else
          loader.add(path: Pathname(FILLS_DIRECTORY))
          @pins = conversions.pins
          @pins.concat RbsMap::CoreFills::ALL
          processed = ApiMap::Store.new(pins).pins.reject { |p| p.is_a?(Solargraph::Pin::Reference::Override) }
          pins.replace processed

          Cache.save('core.ser', pins)
        end
      end

      def pins
        @pins ||= []
      end

      private

      def loader
        @loader ||= RBS::EnvironmentLoader.new(repository: RBS::Repository.new(no_stdlib: false))
      end

      def conversions
        @conversions ||= Conversions.new(loader: loader)
      end
    end
  end
end
