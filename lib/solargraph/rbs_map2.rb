# frozen_string_literal: true

module Solargraph
  class RbsMap2
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

    private

    # @return [RbsMap::Conversions]
    def conversions
      @conversions ||= RbsMap::Conversions.new(loader: loader)
    end
  end
end
