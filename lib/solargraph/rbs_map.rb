require 'rbs'
require 'set'

module Solargraph
  class RbsMap
    autoload :Conversions, 'solargraph/rbs_map/conversions'
    autoload :CoreMap, 'solargraph/rbs_map/core_map'
    autoload :StdlibMap, 'solargraph/rbs_map/stdlib_map'

    include Conversions

    attr_reader :libraries

    def initialize
      loader = RBS::EnvironmentLoader.new core_root: nil, repository: RBS::Repository.new(no_stdlib: true)
      # @type [RBS::Environment]
      environment = RBS::Environment.from_loader(loader).resolve_type_names
      # pins.push Solargraph::Pin::ROOT_PIN
      environment.declarations.each { |decl| convert_decl_to_pin(decl, Solargraph::Pin::ROOT_PIN) }
    end
  end
end
