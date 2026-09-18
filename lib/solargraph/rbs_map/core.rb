# frozen_string_literal: true

module Solargraph
  module RbsMap
    class Core < Base
      FILLS_DIRECTORY = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'rbs', 'fills'))

      def pins
        @pins ||= generate_pins
      end

      # @return [RBS::EnvironmentLoader]
      def loader
        @loader ||= RBS::EnvironmentLoader.new(repository: repository)
      end

      private

      # @return [Array<Pin::Base>]
      def generate_pins
        new_pins = RbsMap::Conversions.new(loader: loader).pins

        # Avoid RBS::DuplicatedDeclarationError by loading in a different EnvironmentLoader
        fill_loader = RBS::EnvironmentLoader.new(core_root: nil, repository: RBS::Repository.new(no_stdlib: false))
        fill_loader.add(path: Pathname(FILLS_DIRECTORY))
        fill_conversions = Conversions.new(loader: fill_loader)
        new_pins.concat fill_conversions.pins

        # add some overrides
        new_pins.concat RbsMap::CoreFills::ALL

        # process overrides, then remove any which couldn't be resolved
        processed = ApiMap::Store.new(new_pins).pins.reject { |p| p.is_a?(Solargraph::Pin::Reference::Override) }
        # serial = Marshal.dump(processed)
        # File.write cache_file, serial, mode: 'wb'
        processed
      end
    end
  end
end
