# frozen_string_literal: true

module Solargraph
  # A collection of pins generated from required gems.
  #
  class DocMap
    # @return [Array<String>]
    attr_reader :requires

    # @return [Array<Gem::Specification>]
    attr_reader :dependencies

    # @return [Array<Pin::Base>]
    attr_reader :pins

    # @return [Array<Gem::Specification>]
    attr_reader :uncached_gemspecs

    # @param requires [Array<String>]
    # @param dependencies [Array<Gem::Specification>]
    def initialize(requires, dependencies)
      @requires = requires
      @dependencies = dependencies
      generate
    end

    # @return [Array<Gem::Specification>]
    def gemspecs
      @gemspecs ||= required_gem_map.values.compact
    end

    # @return [Array<String>]
    def unresolved_requires
      @unresolved_requires ||= required_gem_map.select { |_, gemspec| gemspec.nil? }.keys
    end

    private

    # @return [Hash{String => Gem::Specification, nil}]
    def required_gem_map
      @required_gem_map ||= requires.to_h { |path| [path, resolve_path_to_gemspec(path)] }
    end

    # @return [Hash{String => Gem::Specification}]
    def dependency_map
      @dependency_map ||= dependencies.to_h { |gemspec| [gemspec.name, gemspec] }
    end

    # @return [void]
    def generate
      @pins = []
      @uncached_gemspecs = []
      gemspecs.each do |gemspec|
        cache_file = File.join('gems', "#{gemspec.name}-#{gemspec.version}.ser")
        if Cache.exist?(cache_file)
          @pins.concat Cache.load(cache_file)
        else
          @uncached_gemspecs.push gemspec
        end
      end
    end

    # @param path [String]
    # @return [Gem::Specification, nil]
    def resolve_path_to_gemspec path
      gemspec = Gem::Specification.find_by_path(path)
      return gemspec if dependencies.empty? || gemspec.nil?

      if dependency_map.key?(gemspec.name)
        return gemspec if gemspec.version == dependency_map[gemspec.name].version

        change_gemspec_version gemspec, dependency_map[by_path.name].version
      else
        Solargraph.logger.warn "Gem #{gemspec.name} is not an expected dependency"
        gemspec
      end
    end

    def change_gemspec_version gemspec, version
      Gem::Specification.find_by_name(gemspec.name, "= #{version}")
    rescue Gem::MissingSpecError
      Solargraph.logger.warn "Gem #{gemspec.name} version #{version} not found. Using #{gemspec.version} instead"
      gemspec
    end
  end
end
