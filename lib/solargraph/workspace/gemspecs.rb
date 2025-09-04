# frozen_string_literal: true

require 'rubygems'
require 'bundler'

module Solargraph
  class Workspace
    # Manages determining which gemspecs are available in a workspace
    class Gemspecs
      include Logging

      attr_reader :directory, :preferences

      # @param directory [String, nil] If nil, assume no bundle is present
      # @param preferences [Array<Gem::Specification>]
      def initialize directory, preferences: []
        # @todo an issue with both external bundles and the potential
        #   preferences feature is that bundler gives you a 'clean'
        #   rubygems environment with only the specified versions
        #   installed.  Possible alternatives:
        #
        #   *) prompt the user to run solargraph outside of bundler
        #      and treat all bundles as external
        #   *) reinstall the needed gems dynamically each time
        #   *) manipulate the rubygems/bundler environment
        @directory = directory && File.absolute_path(directory)
        # @todo implement preferences as a config-exposed feature
        @preferences = preferences
      end

      # Take the path given to a 'require' statement in a source file
      # and return the Gem::Specifications which will be brought into
      # scope with it, so we can load pins for them.
      #
      # @param require [String] The string sent to 'require' in the code to resolve, e.g. 'rails', 'bundler/require'
      # @return [::Array<Gem::Specification>, nil]
      def resolve_require require
        return nil if require.empty?
        return gemspecs_required_from_bundler if require == 'bundler/require'

        # @sg-ignore Variable type could not be inferred for gemspec
        # @type [Gem::Specification, nil]
        gemspec = Gem::Specification.find_by_path(require)
        if gemspec.nil?
          gem_name_guess = require.split('/').first
          begin
            # this can happen when the gem is included via a local path in
            # a Gemfile; Gem doesn't try to index the paths in that case.
            #
            # See if we can make a good guess:
            potential_gemspec = Gem::Specification.find_by_name(gem_name_guess)
            file = "lib/#{require}.rb"
            # @sg-ignore Unresolved call to files
            gemspec = potential_gemspec if potential_gemspec.files.any? { |gemspec_file| file == gemspec_file }
          rescue Gem::MissingSpecError
            logger.debug do
              "Require path #{require} could not be resolved to a gem via find_by_path or guess of #{gem_name_guess}"
            end
            []
          end
        end
        return nil if gemspec.nil?
        [gemspec_or_preference(gemspec)]
      end

      # @param gemspec [Gem::Specification]
      # @param out[IO, nil] output stream for logging
      #
      # @return [Array<Gem::Specification>]
      def fetch_dependencies gemspec, out: $stderr
        # @param spec [Gem::Dependency]
        only_runtime_dependencies(gemspec).each_with_object(Set.new) do |spec, deps|
          Solargraph.logger.info "Adding #{spec.name} dependency for #{gemspec.name}"
          dep = Gem.loaded_specs[spec.name]
          # @todo is next line necessary?
          dep ||= Gem::Specification.find_by_name(spec.name, spec.requirement)
          deps.merge fetch_dependencies(dep) if deps.add?(dep)
        rescue Gem::MissingSpecError
          Solargraph.logger.warn "Gem dependency #{spec.name} #{spec.requirement} for " \
                                 "#{gemspec.name} not found in RubyGems."
        end.to_a
      end

      private

      # True if the workspace has a root Gemfile.
      #
      # @todo Handle projects with custom Bundler/Gemfile setups (see DocMap#gemspecs_required_from_bundler)
      #
      def gemfile?
        directory && File.file?(File.join(directory, 'Gemfile'))
      end

      # @return [Hash{String => Gem::Specification}]
      def preference_map
        @preference_map ||= preferences.to_h { |gemspec| [gemspec.name, gemspec] }
      end

      # @param gemspec [Gem::Specification]
      # @return [Gem::Specification]
      def gemspec_or_preference gemspec
        return gemspec unless preference_map.key?(gemspec.name)
        return gemspec if gemspec.version == preference_map[gemspec.name].version

        # @todo this code is unused but broken
        # @sg-ignore Unresolved call to by_path
        change_gemspec_version gemspec, preference_map[by_path.name].version
      end

      # @param gemspec [Gem::Specification]
      # @param version [Gem::Version]
      # @return [Gem::Specification]
      def change_gemspec_version gemspec, version
        Gem::Specification.find_by_name(gemspec.name, "= #{version}")
      rescue Gem::MissingSpecError
        Solargraph.logger.info "Gem #{gemspec.name} version #{version} not found. Using #{gemspec.version} instead"
        gemspec
      end

      # @param gemspec [Gem::Specification]
      # @return [Array<Gem::Dependency>]
      def only_runtime_dependencies gemspec
        gemspec.dependencies - gemspec.development_dependencies
      end

      # @return [Array<Gem::Specification>]
      def gemspecs_required_from_bundler
        # @todo Handle projects with custom Bundler/Gemfile setups
        return unless gemfile?

        if gemfile? && Bundler.definition&.lockfile&.to_s&.start_with?(directory)
          # Find only the gems bundler is now using
          Bundler.definition.locked_gems.specs.flat_map do |lazy_spec|
            logger.info "Handling #{lazy_spec.name}:#{lazy_spec.version}"
            [Gem::Specification.find_by_name(lazy_spec.name, lazy_spec.version)]
          rescue Gem::MissingSpecError => e
            logger.info("Could not find #{lazy_spec.name}:#{lazy_spec.version} with " \
                        'find_by_name, falling back to guess')
            # can happen in local filesystem references
            specs = resolve_require lazy_spec.name
            logger.warn "Gem #{lazy_spec.name} #{lazy_spec.version} from bundle not found: #{e}" if specs.nil?
            next specs
          end.compact
        else
          logger.info 'Fetching gemspecs required from Bundler (bundler/require)'
          gemspecs_required_from_external_bundle
        end
      end

      # @return [Array<Gem::Specification>]
      def gemspecs_required_from_external_bundle
        logger.info 'Fetching gemspecs required from external bundle'
        return [] unless directory

        Solargraph.with_clean_env do
          cmd = [
            'ruby', '-e',
            "require 'bundler'; " \
            "require 'json'; " \
            "Dir.chdir('#{directory}') { " \
            'puts Bundler.definition.locked_gems.specs.map { |spec| [spec.name, spec.version] }' \
            '.to_h.to_json }'
          ]
          o, e, s = Open3.capture3(*cmd)
          if s.success?
            Solargraph.logger.debug "External bundle: #{o}"
            hash = o && !o.empty? ? JSON.parse(o.split("\n").last) : {}
            hash.flat_map do |name, version|
              Gem::Specification.find_by_name(name, version)
            rescue Gem::MissingSpecError => e
              logger.info("Could not find #{name}:#{version} with find_by_name, falling back to guess")
              # can happen in local filesystem references
              specs = resolve_require name
              logger.warn "Gem #{name} #{version} from bundle not found: #{e}" if specs.nil?
              next specs
            end.compact
          else
            Solargraph.logger.warn "Failed to load gems from bundle at #{directory}: #{e}"
          end
        end
      end
    end
  end
end
