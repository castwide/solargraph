# frozen_string_literal: true

module Solargraph
  module RbsMap
    class Core < Base
      FILLS_DIRECTORY = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'rbs', 'fills'))

      # Like FILLS_DIRECTORY, but a declaration here *replaces* the core
      # definition of the same method path rather than adding an overload
      # alongside it.
      OVERRIDES_DIRECTORY = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'rbs', 'overrides'))

      def pins
        @pins ||= generate_pins
      end

      # @return [RBS::EnvironmentLoader]
      def loader
        @loader ||= RBS::EnvironmentLoader.new(repository: repository)
      end

      def repository
        @repository ||= RBS::Repository.new(no_stdlib: false)
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

        override_loader = RBS::EnvironmentLoader.new(core_root: nil, repository: RBS::Repository.new(no_stdlib: false))
        override_loader.add(path: Pathname(OVERRIDES_DIRECTORY))
        override_pins = Conversions.new(loader: override_loader).pins
        # An override replaces what core declared for that path.
        overridden = override_pins.grep(Pin::Method).to_set(&:path)
        # @sg-ignore https://github.com/castwide/solargraph/pull/1266
        new_pins.reject! { |pin| pin.is_a?(Pin::Method) && overridden.include?(pin.path) }
        new_pins.concat override_pins

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
