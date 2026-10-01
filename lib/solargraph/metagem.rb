# frozen_string_literal: true

module Solargraph
  class Metagem
    include Equality

    # @return [String]
    attr_reader :name

    # @return [String]
    attr_reader :full_path

    # @return [String]
    attr_reader :spec_file

    # @return [String]
    attr_reader :source

    # @return [String]
    attr_reader :version

    # @return [Array<String>]
    attr_reader :require_paths

    # @return [Array<String>]
    attr_reader :dependencies

    # @return [String]
    attr_reader :cache_name

    # @param name [String]
    # @param full_path [String]
    # @param spec_file [String]
    # @param source [String]
    # @param version [String]
    # @param require_paths [Array<String>]
    # @param dependencies [Array<String>]
    def initialize name:, full_path:, spec_file:, source:, version:, require_paths:, dependencies:
      @name = name
      @full_path = full_path
      @spec_file = spec_file
      @source = source
      @version = version
      @require_paths = require_paths
      @dependencies = dependencies
      # @todo Possible change to cache names to make them more specific to sources
      # @cache_name = "#{File.basename(full_path)}__#{source.gsub(/[^a-z0-9\-_]/i, '_')}" unless source.end_with?('Path')
      # @todo Better path source detection
      @cache_name = File.basename(full_path) unless source.start_with?('source at') || source.to_s.end_with?('::Path')
    end

    def cacheable?
      !!@cache_name
    end

    # @param path [String]
    def require? path
      require_paths.any? do |req|
        File.file?(File.join(full_path, req, "#{path}.rb"))
      end
    end

    # @return [Gem::Specification, nil]
    # @sg-ignore a singleton .load with no declared return falls back to Kernel#load
    def to_specification
      Gem::Specification.load(spec_file)
    end

    alias full_gem_path full_path

    # @return [Array]
    def equality_fields
      # A version arrives as a String from a bundle definition and as a
      # Gem::Version from a specification, so compare its string form.
      [name, version.to_s, full_path, source]
    end

    # @param gem [Gem::Specification]
    # @return [Metagem]
    def self.from_specification gem
      # @sg-ignore https://github.com/castwide/solargraph/pull/1245
      Metagem.new(name: gem.name,
                  full_path: gem.full_gem_path,
                  spec_file: gem.spec_file,
                  source: gem.source.to_s,
                  version: gem.version,
                  require_paths: gem.require_paths,
                  dependencies: gem.runtime_dependencies.map(&:name))
    end
  end
end
