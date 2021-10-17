module Solargraph
  class RbsMap
    class CoreMap
      include Conversions

      def initialize
        cache = Cache.load('core.ser')
        if cache
          pins.replace cache
        else
          loader = RBS::EnvironmentLoader.new(repository: RBS::Repository.new(no_stdlib: true))
          environment = RBS::Environment.from_loader(loader).resolve_type_names
          environment.declarations.each { |decl| convert_decl_to_pin(decl, Solargraph::Pin::ROOT_PIN) }
          pins.concat YardMap::CoreFills::ALL
          processed = ApiMap::Store.new(pins).pins.reject { |p| p.is_a?(Solargraph::Pin::Reference::Override) }
          pins.replace processed

          # HACK: Add Errno exception classes
          # @todo This will need to be uncommented if/when we stop using YardMap core fills
          # errno = Solargraph::Pin::Namespace.new(name: 'Errno')
          # Errno.constants.each do |const|
          #   pins.push Solargraph::Pin::Namespace.new(type: :class, name: const.to_s, closure: errno)
          #   pins.push Solargraph::Pin::Reference::Superclass.new(closure: pins.last, name: 'SystemCallError')
          # end

          Cache.save('core.ser', pins)
        end
      end

      def method_def_to_sigs decl, pin
        stubs = CoreFills.fill(pin.path)
        return super unless stubs
        stubs.map do |stub|
          Pin::Signature.new(
            [],
            ComplexType.try_parse(stub.return_type)
          )
        end
      end

      def self.new
        @@cache ||= super
      end
    end
  end
end
