# frozen_string_literal: true

module Solargraph
  class RbsMap
    # Ruby core pins
    #
    class CoreMap
      include Logging

      def resolved?
        true
      end

      FILLS_DIRECTORY = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'rbs', 'fills'))

      def initialize; end

      def pins
        return @pins if @pins

        @pins = []
        cache = PinCache.deserialize_core
        if cache
          @pins.replace cache
        else
          @pins.concat conversions.pins

          # Avoid RBS::DuplicatedDeclarationError by loading in a different EnvironmentLoader
          fill_loader = RBS::EnvironmentLoader.new(core_root: nil, repository: RBS::Repository.new(no_stdlib: false))
          fill_loader.add(path: Pathname(FILLS_DIRECTORY))
          fill_conversions = Conversions.new(loader: fill_loader)
          @pins.concat fill_conversions.pins

          @pins.concat RbsMap::CoreFills::ALL

          processed = ApiMap::Store.new(pins).pins.reject { |p| p.is_a?(Solargraph::Pin::Reference::Override) }
          @pins.replace processed

          PinCache.serialize_core @pins
        end
        @pins
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
