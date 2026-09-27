# frozen_string_literal: true

require 'yaml'

module Solargraph
  # The RBS collection a workspace directory configures, and which gems it
  # carries signatures for.
  #
  module RbsCollection
    module_function

    # @param directory [String, nil]
    # @return [String, nil]
    def config_path directory
      # @todo Get rid of the '*' case
      return if directory.nil? || directory.empty? || directory == '*'

      yaml_file = File.join(directory, 'rbs_collection.yaml')
      yaml_file if File.file?(yaml_file)
    end

    # The installed collection, plus any source the workspace keeps locally.
    #
    # @param directory [String, nil]
    # @return [Array<String>]
    def paths directory
      config = config_path(directory)
      return [] unless config

      yaml = YAML.load_file(config)
      [File.expand_path(yaml.fetch('path'), directory)].concat(
        yaml.fetch('sources', [])
            .select { |source| source['type'] == 'local' && source['path'] }
            .map { |source| File.expand_path(source['path'], directory) }
      ).compact
    end

    # Each source names its gems by directory.
    #
    # @param directory [String, nil]
    # @param gem_name [String]
    # @return [Boolean]
    def provides? directory, gem_name
      paths(directory).any? { |path| Dir.exist?(File.join(path, gem_name)) }
    end
  end
end
