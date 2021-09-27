module Solargraph
  class RbsMap
    class CoreMap
      include Conversions

      def initialize
        loader = RBS::EnvironmentLoader.new(repository: RBS::Repository.new(no_stdlib: true))
        # @type [RBS::Environment]
        environment = RBS::Environment.from_loader(loader).resolve_type_names
        environment.declarations.each { |decl| convert_decl_to_pin(decl, Solargraph::Pin::ROOT_PIN) }
        pins.concat YardMap::CoreFills::ALL
      end
    end
  end
end
