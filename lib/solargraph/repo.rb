# frozen_string_literal: true

require 'set'
require 'yaml'

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

    # Load metagems by parsing the directory's Gemfile.lock if available.
    #
    # Parsing the lockfile is significantly faster and less intrusive than
    # evaluating the bundle definition, which can execute arbitrary code from
    # the Gemfile and emit output in the host process.
    #
    # @return [Array<Metagem>, nil]
    def build_from_directory
      return unless bundled_directory? && ENV['BUNDLE_GEMFILE'] != gemfile

      require 'bundler'
      parser = Bundler::LockfileParser.new(File.read(lockfile))
      metagems = []
      parsed = Set.new
      parser.specs.each do |spec|
        # The lockfile may include multiple platform-specific variants of the
        # same gem; they collapse to a single name/version pair.
        next unless parsed.add?("#{spec.name} #{spec.version}")
        metagem = metagem_from_lock(spec)
        metagems << metagem if metagem
      end
      @metagems = metagems
      # Gemfile.lock does not record bundle groups, so direct dependencies
      # are treated as members of the :default group.
      @bundled_group_map = {
        default: parser.dependencies.filter_map { |name, _dep| bundled_metagem_name_map[name] }
      }
    rescue StandardError => e
      Solargraph.logger.warn "Failed to load gems from bundle at #{directory}: #{e}"
      @metagems = nil
      @bundled_group_map = {}
      nil
    end

    # Build a metagem from a locked specification.
    #
    # @param spec [Bundler::LazySpecification]
    # @return [Metagem, nil]
    def metagem_from_lock spec
      # NOTE: Bundler::Source::Git is a subclass of Bundler::Source::Path, so
      # it must be matched first.
      case spec.source
      when Bundler::Source::Git
        git_gem_from_lock(spec)
      when Bundler::Source::Path
        path_gem_from_lock(spec)
      else
        installed_gem_from_lock(spec)
      end
    end

    # @param spec [Bundler::LazySpecification]
    # @return [Metagem, nil]
    def installed_gem_from_lock spec
      gemspec = find_installed_gemspec(spec.name, spec.version.to_s)
      unless gemspec
        Solargraph.logger.warn "Skipping #{spec.name} (#{spec.version}): not installed"
        return
      end
      Metagem.new(name: spec.name,
                  full_path: gemspec.full_gem_path,
                  spec_file: gemspec.spec_file,
                  source: rubygems_source_string(spec.source),
                  version: spec.version.to_s,
                  require_paths: gemspec.require_paths,
                  dependencies: spec.dependencies.map(&:name))
    end

    # @param spec [Bundler::LazySpecification]
    # @return [Metagem]
    def path_gem_from_lock spec
      options = spec.source.options || {}
      remote = options['path'] || options['remote']
      root = File.expand_path(remote.to_s, directory)
      spec_file = File.join(root, "#{spec.name}.gemspec")
      spec_file = Dir[File.join(root, '*.gemspec')].first unless File.file?(spec_file)
      gemspec = spec_file && File.file?(spec_file) ? Gem::Specification.load(spec_file) : nil
      Metagem.new(name: spec.name,
                  full_path: root,
                  spec_file: spec_file,
                  source: "source at #{root}",
                  version: spec.version.to_s,
                  require_paths: gemspec&.require_paths || ['lib'],
                  dependencies: spec.dependencies.map(&:name))
    end

    # @param spec [Bundler::LazySpecification]
    # @return [Metagem, nil]
    def git_gem_from_lock spec
      options = spec.source.options || {}
      revision = (options['revision'] || options['commit']).to_s
      scope = revision[0, 12]
      git_home_paths.each do |home|
        Dir[File.join(home, 'bundler', 'gems', "*#{spec.name}-#{scope}*")].each do |dir|
          spec_file = File.join(dir, "#{spec.name}.gemspec")
          spec_file = Dir[File.join(dir, '*.gemspec')].first unless File.file?(spec_file)
          next unless spec_file && File.file?(spec_file)
          gemspec = Gem::Specification.load(spec_file)
          return Metagem.new(name: spec.name,
                             full_path: dir,
                             spec_file: spec_file,
                             source: spec.source.to_s,
                             version: spec.version.to_s,
                             require_paths: gemspec&.require_paths || ['lib'],
                             dependencies: spec.dependencies.map(&:name))
        end
      end
      Solargraph.logger.warn "Skipping #{spec.name} (#{spec.version}): git gem not found in bundle path"
      nil
    end

    # Locate an installed gemspec by name and version, searching both the
    # system gems and any local bundle path configured for the directory.
    #
    # @param name [String]
    # @param version [String]
    # @return [Gem::Specification, nil]
    def find_installed_gemspec name, version
      # Gems installed to a local bundle path take precedence, mirroring the
      # resolution performed by Bundler at runtime.
      find_gemspec_in_homes(local_gem_home_paths, name, version) ||
        Gem::Specification.find_all_by_name(name).find { |gs| gs.version.to_s == version } ||
        find_gemspec_in_homes(gem_home_paths, name, version) ||
        find_gemspec_fallback(name, version)
    end

    # @param homes [Array<String>]
    # @param name [String]
    # @param version [String]
    # @return [Gem::Specification, nil]
    def find_gemspec_in_homes homes, name, version
      homes.each do |home|
        file = locate_spec_file(home, name, version)
        next unless file
        begin
          return Gem::Specification.load(file)
        rescue StandardError => e
          Solargraph.logger.warn "Failed to load gemspec #{file}: #{e}"
        end
      end
      nil
    end

    def find_gemspec_fallback name, version
      found = Gem::Specification.find_by_name(name)
      Solargraph.logger.warn "Repo could not find #{name} #{version} in current environment, defaulting to #{name} #{found.version}"
      found
    end

    # Find a gemspec file in a gem home, accounting for platform-specific
    # variants such as name-1.0.0-x86_64-linux.gemspec.
    #
    # @param home [String]
    # @param name [String]
    # @param version [String]
    # @return [String, nil]
    def locate_spec_file home, name, version
      exact = File.join(home, 'specifications', "#{name}-#{version}.gemspec")
      return exact if File.file?(exact)
      variants = Dir[File.join(home, 'specifications', "#{name}-#{version}-*.gemspec")].select { |f| File.file?(f) }
      local = variants.find { |f| File.basename(f) == "#{name}-#{version}-#{Gem::Platform.local}.gemspec" }
      local || variants.first
    end

    # All gem home directories to search for installed gems.
    #
    # @return [Array<String>]
    def gem_home_paths
      @gem_home_paths ||= (local_gem_home_paths + Gem.path + [Gem.default_dir, Gem.user_dir]).uniq
    end

    # @param source [Bundler::Source::Rubygems]
    # @return [String]
    def rubygems_source_string source
      remotes = source.respond_to?(:remotes) ? source.remotes : []
      remotes.empty? ? 'https://rubygems.org' : remotes.map { |r| r.to_s.chomp('/') }.join(',')
    end

    # The base directory in which Bundler installs gems, including any path
    # configured via `bundle config path`.
    #
    # @return [Array<String>]
    def local_gem_home_paths
      @local_gem_home_paths ||= begin
        paths = []
        setting = bundle_config_setting('BUNDLE_PATH')
        if setting && setting != 'system'
          base = File.expand_path(setting, directory)
          paths.push File.join(base, 'ruby', RbConfig::CONFIG['ruby_version']), base
        end
        paths
      end
    end

    # @return [Array<String>]
    def git_home_paths
      @git_home_paths ||= (local_gem_home_paths + [Gem.default_dir, Gem.user_dir] + Gem.path).uniq
    end

    # Read a setting from the directory's local .bundle/config file.
    #
    # @param key [String]
    # @return [String, nil]
    def bundle_config_setting key
      file = File.join(directory, '.bundle', 'config')
      return unless File.file?(file)
      config = YAML.load_file(file)
      return unless config.is_a?(Hash)
      value = config[key] || config[key.downcase]
      value = value['value'] || value[:value] if value.is_a?(Hash)
      value&.to_s
    rescue StandardError => e
      Solargraph.logger.warn "Failed to read #{file}: #{e}"
      nil
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
