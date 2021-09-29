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
          # @type [RBS::Environment]
          environment = RBS::Environment.from_loader(loader).resolve_type_names
          environment.declarations.each { |decl| convert_decl_to_pin(decl, Solargraph::Pin::ROOT_PIN) }
          pins.concat YardMap::CoreFills::ALL
          Cache.save('core.ser', pins)
        end
      end

      def self.new
        @@cache ||= super
      end
    end
  end
end
