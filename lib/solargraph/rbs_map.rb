require 'rbs'
require 'set'

module Solargraph
  class RbsMap
    autoload :Conversions, 'solargraph/rbs_map/conversions'
    autoload :CoreMap, 'solargraph/rbs_map/core_map'

    include Conversions

    @@rbs_maps_hash = {}

    attr_reader :library

    def initialize library
      @library = library
      loader = RBS::EnvironmentLoader.new(core_root: nil)
      add_library loader, library
      return unless resolved?
      # @type [RBS::Environment]
      environment = RBS::Environment.from_loader(loader).resolve_type_names
      environment.declarations.each { |decl| convert_decl_to_pin(decl, Solargraph::Pin::ROOT_PIN) }
    end

    def resolved?
      @resolved
    end

    def self.load library
      @@rbs_maps_hash[library] ||= RbsMap.new(library)
    end

    private

    def add_library loader, library
      @resolved = if loader.has_library?(library: library, version: nil)
        loader.add library: library
        true
      else
        Solargraph.logger.warn "RBS mapper rejected unknown library #{library}"
        false
      end  
    end
  end
end
