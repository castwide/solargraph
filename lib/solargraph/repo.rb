# frozen_string_literal: true

require 'open3'

module Solargraph
  # A repository for the gems available in the specified directory. If the
  # directory has a Gemfile, Repo will use its gem definitions. Otherwise it
  # uses the system gems.
  #
  class Repo
    # @param directory [String, nil]
    def initialize directory
      @directory = directory
      @metagems = build_from_directory
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
      return system_find_by_name(name) unless @metagems

      bundled_metagem_name_map[name]&.first
    end

    # True if the directory has a bundle definition.
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
      @gemfile ||= File.expand_path('Gemfile', @directory) if @directory
    end

    # @return [String, nil]
    def lockfile
      @lockfile ||= File.expand_path('Gemfile.lock', @directory) if @directory
    end

    def bundled_directory?
      @directory && File.file?(gemfile) && File.file?(lockfile)
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
        cmd = ['ruby', '-e', bundle_script]
        o, e, s = Open3.capture3(*cmd, chdir: @directory)
        if s.success?
          json = o && !o.empty? ? JSON.parse(o.strip.split("\n").last, symbolize_names: true) : []
          json.map { |data| Metagem.new(**data) }
        else
          Solargraph.logger.warn "Failed to load gems from bundle at #{@directory}: #{e}"
          nil
        end
      end
    end

    def bundle_script
      "
        require 'bundler/setup'
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
        puts metagems.to_json
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

    def bundled_metagem_name_map
      @bundled_metagem_name_map ||= bundled.to_set.classify(&:name)
    end

    def bundled_metagem_path_map
      @bundled_metagem_path_map ||= Hash.new do |hash, path|
        hash[path] = bundled.find { |mg| mg.require?(path) }
      end
    end
  end
end
