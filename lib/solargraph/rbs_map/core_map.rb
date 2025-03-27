# frozen_string_literal: true

module Solargraph
  class RbsMap
    # Ruby core pins
    #
    class CoreMap
      include Conversions

      FILLS_DIRECTORY = File.join(File.dirname(__FILE__), '..', '..', '..', 'rbs', 'fills')

      def initialize
        cache = Cache.load('core.ser')
        if cache
          pins.replace cache
        else
          loader = RBS::EnvironmentLoader.new(repository: RBS::Repository.new(no_stdlib: false))
          loader.add(path: Pathname(FILLS_DIRECTORY))
          load_environment_to_pins(loader)
          pins.concat RbsMap::CoreFills::ALL
          processed = ApiMap::Store.new(pins).pins.reject { |p| p.is_a?(Solargraph::Pin::Reference::Override) }
          pins.replace processed

          Cache.save('core.ser', pins)
        end
      end

      def method_def_to_sigs decl, pin
        stubs = CoreSigns.sign(pin.path)
        return super unless stubs
        stubs.map do |stub|
          Pin::Signature.new(
            [],
            [],
            ComplexType.try_parse(stub.return_type)
          )
        end
      end
    end
  end
end
