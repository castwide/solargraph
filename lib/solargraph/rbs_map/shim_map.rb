# frozen_string_literal: true

module Solargraph
  class RbsMap
    # User-provided pins
    #
    class ShimMap
      include Conversions

      # @param shims_dir [String]
      def initialize(shims_dir)
        loader = RBS::EnvironmentLoader.new(core_root: nil)
        loader.add(path: Pathname(shims_dir))
        load_environment_to_pins(loader)
        pins.each { |pin| pin.source = :shim }
      end
    end
  end
end
