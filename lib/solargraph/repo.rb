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

    def bundle?
      !!@metagems
    end

    def bundled
      @metagems || []
    end

    private

    def build_from_directory
      return unless @directory && File.file?(File.join(@directory, 'Gemfile'))

      Solargraph.with_clean_env do
        Dir.chdir(@directory) do
          Bundler.definition.specs.map do |spec|
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
        end
      end
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
