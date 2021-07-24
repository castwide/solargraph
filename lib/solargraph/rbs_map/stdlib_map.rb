module Solargraph
  class RbsMap
    class StdlibMap
      include Conversions

      @@stdlib_maps_hash = {}

      attr_reader :library

      def initialize library
        @library = library
        loader = RBS::EnvironmentLoader.new(core_root: nil)
        @resolved = add_library(loader, library)
        # @type [RBS::Environment]
        environment = RBS::Environment.from_loader(loader).resolve_type_names
        pins.push Solargraph::Pin::ROOT_PIN
        environment.declarations.each { |decl| convert_decl_to_pin(decl, Solargraph::Pin::ROOT_PIN) }
      end

      def resolved?
        @resolved
      end

      def self.load library
        @@stdlib_maps_hash[library] ||= StdlibMap.new(library)
      end

      private

      def add_library loader, library
        if loader.has_library?(library: library, version: nil)
          loader.add library: library
          true
        else
          # unresolved_libraries.push name
          Solargraph.logger.warn "RBS mapper rejected unknown library #{library}"
          false
        end  
      end
    end
  end
end
