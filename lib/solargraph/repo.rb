# frozen_string_literal: true

module Solargraph
  # A repository for the gems available in the specified directory. If the
  # directory has a Gemfile, Repo will use its gem definitions. Otherwise it
  # uses the system gems.
  #
  class Repo
    def initialize directory
      @directory = directory
      @metagems = build_from_directory
    end

    def find_by_path path
      return system_find_by_path(path) unless @metagems

      @metagems.find { |mg| mg.require?(path) }
    end

    def find_by_name name
      return system_find_by_name(name) unless @metagems

      @metagems.find { |mg| mg.name == name }
    end

    def bundled?
      !!@metagems
    end
    alias bundle? bundled?

    def bundled
      @metagems || []
    end

    private

    def gemfile
      @gemfile ||= File.expand_path('Gemfile', @directory)
    end

    def lockfile
      @lockfile ||= File.expand_path('Gemfile.lock', @directory)
    end

    def bundled_directory?
      File.file?(gemfile) && File.file?(lockfile)
    end

    def bundle_definition
      @bundle_definition ||= if bundled_directory? && ENV['BUNDLE_GEMFILE'] != gemfile
        Bundler::Definition.build(gemfile, lockfile, nil)
      elsif ENV['BUNDLE_GEMFILE']
        Bundler.definition
      else
        nil
      end
    end

    def build_from_directory
      return unless bundle_definition

      # @todo Smelly suppression of output from Bundler::Definition#specs
      $stdout = StringIO.new
      bundle_definition.specs.map do |spec|
        Metagem.new(
          name: spec.name,
          full_path: spec.full_gem_path,
          spec_file: spec.spec_file,
          source: spec.source.to_s,
          version: spec.version,
          require_paths: spec.require_paths,
          dependencies: spec.dependencies.map(&:name)
        )
      end
    rescue StandardError => e
      Solargraph.logger.warn "Failed to load gems from bundle at #{@directory}: [#{e.class}] #{e.message}"
      nil
    ensure
      # @todo Smelly suppression of output from Bundler::Definition#specs
      $stdout = STDOUT
    end

    def system_find_by_path path
      gem = Gem::Specification.find_by_path(path)
      gem && Metagem.from_specification(gem)
    end

    def system_find_by_name name
      gem = Gem::Specification.find_by_name(name)
      gem && Metagem.from_specification(gem)
    rescue Gem::MissingSpecError => _e
      nil
    end
  end
end
