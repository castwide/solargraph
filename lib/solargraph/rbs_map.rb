# frozen_string_literal: true

require 'rbs'

module Solargraph
  class RbsMap
    autoload :Conversions, 'solargraph/rbs_map/conversions'
    autoload :CoreMap,     'solargraph/rbs_map/core_map'
    autoload :CoreFills,   'solargraph/rbs_map/core_fills'
    autoload :StdlibMap,   'solargraph/rbs_map/stdlib_map'

    # @param metagem [Metagem]
    def initialize metagem
      loader.add path: Pathname.new(metagem.full_path)
    end

    def pins
      @pins ||= conversions.pins
    end

    # @return [RBS::Repository]
    def repository
      @repository ||= RBS::Repository.new(no_stdlib: false)
    end

    # @return [RBS::EnvironmentLoader]
    def loader
      @loader ||= RBS::EnvironmentLoader.new(core_root: nil, repository: repository)
    end

    # @param path [String]
    # @return [Pin::Base, nil]
    def path_pin path
      pins.find { |p| p.path == path }
    end

    private

    # @return [RbsMap::Conversions]
    def conversions
      @conversions ||= RbsMap::Conversions.new(loader: loader)
    end
  end
end
