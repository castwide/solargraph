# frozen_string_literal: true

module Solargraph
  class RbsMap
    # Ruby core pins
    #
    class CoreMap

      def resolved?
        true
      end

      FILLS_DIRECTORY = File.join(File.dirname(__FILE__), '..', '..', '..', 'rbs', 'fills')

      def initialize; end

      # @return [Array<Pin::Base>]
      def pins(out: $stderr)
        return @pins if @pins
        @pins = cache_core(out: out)
      end

      def cache_core(out: $stderr)
        new_pins = []
        cache = PinCache.load_core
        if cache
          return cache
        else
          new_pins.concat conversions.pins

          # Avoid RBS::DuplicatedDeclarationError by loading in a different EnvironmentLoader
          fill_loader = RBS::EnvironmentLoader.new(core_root: nil, repository: RBS::Repository.new(no_stdlib: false))
          fill_loader.add(path: Pathname(FILLS_DIRECTORY))
          out.puts "Caching RBS pins for Ruby core" if out
          fill_conversions = Conversions.new(loader: fill_loader)
          new_pins.concat fill_conversions.pins

          new_pins.concat RbsMap::CoreFills::ALL

          processed = ApiMap::Store.new(new_pins).pins.reject { |p| p.is_a?(Solargraph::Pin::Reference::Override) }
          new_pins.replace processed

          PinCache.serialize_core new_pins
        end
        new_pins

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
