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

      # @param out [IO, nil] output stream for logging
      # @return [Enumerable<Pin::Base>]
      def pins out: $stderr
        return @pins if @pins
        @pins = cache_core(out: out)
      end

      # @param out [StringIO, IO, nil] output stream for logging
      # @return [Array<Pin::Base>]
      def cache_core out: $stderr
        new_pins = []
        cache = PinCache.deserialize_core
        return cache if cache
        new_pins.concat conversions.pins

        # Avoid RBS::DuplicatedDeclarationError by loading in a different EnvironmentLoader
        fill_loader = RBS::EnvironmentLoader.new(core_root: nil, repository: RBS::Repository.new(no_stdlib: false))
        fill_loader.add(path: Pathname(FILLS_DIRECTORY))
        out&.puts 'Caching RBS pins for Ruby core'
        fill_conversions = Conversions.new(loader: fill_loader)
        new_pins.concat fill_conversions.pins

        # add some overrides
        new_pins.concat RbsMap::CoreFills::ALL

        # process overrides, then remove any which couldn't be resolved
        processed = ApiMap::Store.new(new_pins).pins.reject { |p| p.is_a?(Solargraph::Pin::Reference::Override) }
        new_pins.replace processed

        PinCache.serialize_core new_pins

        new_pins
      end

      private

      # @return [RBS::EnvironmentLoader]
      def loader
        @loader ||= RBS::EnvironmentLoader.new(repository: RBS::Repository.new(no_stdlib: false))
      end

      # @return [Conversions]
      def conversions
        @conversions ||= Conversions.new(loader: loader)
      end
    end
  end
end
