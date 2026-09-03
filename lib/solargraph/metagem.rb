# frozen_string_literal: true

module Solargraph
  class Metagem
    attr_reader :name

    attr_reader :full_path

    attr_reader :source

    attr_reader :version

    attr_reader :require_paths

    attr_reader :dependencies

    attr_reader :cache_name

    def initialize name:, full_path:, spec_file:, source:, version:, require_paths:, dependencies:
      @name = name
      @full_path = full_path
      @spec_file = spec_file
      @source = source
      @version = version
      @require_paths = require_paths
      @dependencies = dependencies
      @cache_name = File.basename(full_path) unless source.end_with?('Path')
    end

    def cacheable?
      !!@cache_name
    end

    def require? path
      require_paths.each do |req|
        return true if File.file?(File.join(full_path, req, "#{path}.rb"))
      end
      false
    end

    def self.from_specification gem
      Metagem.new(name: gem.name, full_path: gem.full_gem_path, spec_file: gem.spec_file, source: gem.source.class.name, version: gem.version, require_paths: gem.require_paths, dependencies: gem.dependencies.map(&:name))
    end
  end
end
