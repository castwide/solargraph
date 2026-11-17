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

    def initialize name:, full_path:, spec_file:, source:, version:, dependencies:, require_paths: nil
      @name = name
      @full_path = full_path
      @spec_file = spec_file
      @source = source
      @version = version
      @require_paths = require_paths || Metagem.parse_require_paths(spec_file)
      @dependencies = dependencies
      # @todo Possible change to cache names to make them more specific to sources
      # @cache_name = "#{File.basename(full_path)}__#{source.gsub(/[^a-z0-9\-_]/i, '_')}" unless source.end_with?('Path')
      # @todo Better path source detection
      @cache_name = File.basename(full_path) unless source.start_with?('source at') || source.to_s.end_with?('::Path')
    end

    def cacheable?
      !!@cache_name
    end

    def require? path
      require_paths.any? do |req|
        File.file?(File.join(full_path, req, "#{path}.rb"))
      end
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
      Metagem.new(name: gem.name,
                  full_path: gem.full_gem_path,
                  spec_file: gem.spec_file,
                  source: gem.source.to_s,
                  version: gem.version,
                  require_paths: gem.require_paths,
                  dependencies: gem.runtime_dependencies.map(&:name))
    end

    # @parse [String, nil]
    # @return [Array<String>]
    def self.parse_require_paths spec_file
      return ['lib'] unless spec_file && File.file?(spec_file)

      source = Solargraph::Source.load(spec_file)
      node = Parser::NodeMethods.call_nodes_from(source.node)
                                .flatten
                                .find { |node| node.children[1] == :require_paths= }
      return ['lib'] unless node &&
                            node.children[2]&.type == :array &&
                            node.children[2].children.all? { |elem| elem.type == :str }

      node.children[2]
          .children
          .map { |elem| elem.children[0] }
    end
  end
end
