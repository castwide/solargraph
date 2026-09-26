# frozen_string_literal: true

require 'open3'
require 'json'

module Solargraph
  # A repository for the gems available in the specified directory. If the
  # directory has a Gemfile, Repo will use its gem definitions. Otherwise it
  # uses the system gems.
  #
  class Repo
    # @return [String, nil]
    attr_reader :directory

    # @param directory [String, nil]
    def initialize directory
      @directory = File.expand_path(directory) if directory
      build_from_directory
    end

    # Find a metagem by path from the directory's bundle definition or the
    # system gems.
    #
    # @param path [String]
    # @return [Metagem, nil]
    def find_by_path path
      return system_find_by_path(path) unless bundled?

      bundled_metagem_path_map[path]
    end

    # Find a metagem by name from the directory's bundle definition or the
    # system gems.
    #
    # @param name [String]
    # @return [Metagem, nil]
    def find_by_name name
      return system_find_by_name(name) unless bundled?

      bundled_metagem_name_map[name]
    end

    # Get an array of metagems by its bundle group name. Returns an empty array
    # if the repo isn't bundled or the group doesn't exist.
    #
    # @param group [Symbol]
    # @return [Array<Metagem>]
    def find_by_group group
      return system_find_by_group(group) unless bundled?

      bundled_group_map[group] || []
    end

    # True if the directory has a bundle definition.
    #
    # @note If Solargraph itself is running in this directory's bundled
    #   environment, `bundled?` is false.
    #
    def bundled?
      !!@metagems
    end
    alias bundle? bundled?

    # Metagems from the directory's bundle definition, or an empty array if a
    # bundle definition does not exist.
    #
    # @return [Array<Solargraph::Metagem>]
    def bundled
      @metagems || []
    end

    private

    # @return [String, nil]
    def gemfile
      @gemfile ||= File.expand_path('Gemfile', directory) if directory
    end

    # @return [String, nil]
    def lockfile
      @lockfile ||= File.expand_path('Gemfile.lock', directory) if directory
    end

    def bundled_directory?
      directory && File.file?(gemfile) && File.file?(lockfile)
    end

    # Load metagems from the directory's bundle definition if available.
    #
    # This method performs gem collection in a separate process to suppress
    # output from the `Bundler.definition.specs` call.
    #
    # @return [Array<Metagem>, nil]
    def build_from_directory
      return unless bundled_directory? && ENV['BUNDLE_GEMFILE'] != gemfile

      Solargraph.with_clean_env do
        cmd = ['bundle', 'exec', 'ruby', '-e', bundle_script]
        o, e, s = Open3.capture3(*cmd, chdir: directory)
        if s.success?
          json = o && !o.empty? ? JSON.parse(o.strip.split("\n").last, symbolize_names: true) : []
          @metagems = json[:metagems].map { |data| Metagem.new(**data) }
          @bundled_group_map = json[:groups].transform_values { |names| names.map { |name| bundled_metagem_name_map[name] } }
        else
          Solargraph.logger.warn "Failed to load gems from bundle at #{directory}: #{e}"
          nil
        end
      end
    end

    def bundle_script
      "
        require 'json'

        metagems = Bundler.definition.specs.map do |spec|
          {
            name: spec.name,
            full_path: spec.full_gem_path,
            spec_file: spec.spec_file,
            source: spec.source.to_s,
            version: spec.version,
            require_paths: spec.require_paths,
            dependencies: spec.dependencies.map(&:name)
          }
        end
        groups = Bundler.definition.groups.to_h do |group|
          [group, Bundler.definition.specs_for([group]).map(&:name)]
        end
        puts({ groups: groups, metagems: metagems }.to_json)
      "
    end

    # @param path [String]
    # @return [Metagem, nil]
    def system_find_by_path path
      gem = Gem::Specification.find_by_path(path)
      gem && Metagem.from_specification(gem)
    end

    # @param name [String]
    # @return [Metagem, nil]
    def system_find_by_name name
      gem = Gem::Specification.find_by_name(name)
      gem && Metagem.from_specification(gem)
    rescue Gem::MissingSpecError => _e
      nil
    end

    # @param group [Symbol]
    # @return [Array<Metagem>]
    def system_find_by_group group
      return [] unless ENV['BUNDLE_GEMFILE']

      Bundler.definition
             .specs_for([group])
             .map { |spec| Metagem.from_specification(spec) }
    end

    def bundled_metagem_name_map
      @bundled_metagem_name_map ||= bundled.to_set
                                           .classify(&:name)
                                           .transform_values(&:first)
    end

    def bundled_metagem_path_map
      @bundled_metagem_path_map ||= Hash.new do |hash, path|
        hash[path] = bundled.find { |mg| mg.require?(path) }
      end
    end

    def bundled_group_map
      @bundled_group_map ||= {}
    end
  end
end
