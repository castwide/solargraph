# frozen_string_literal: true

require 'bundler'

module Solargraph
  class Workspace
    # Manages determining which gemspecs are available in a workspace
    class Gemspecs
      include Logging

      attr_reader :directory, :preferences

      # @param directory [String]
      def initialize directory
        @directory = directory
        # @todo implement preferences
        @preferences = []
      end

      # Take the path given to a 'require' statement in a source file
      # and return the Gem::Specifications which will be brought into
      # scope with it, so we can load pins for them.
      #
      # @param require [String] The string sent to 'require' in the code to resolve, e.g. 'rails', 'bundler/require'
      # @return [::Array<Gem::Specification>, nil]
      def resolve_require require
        return nil if require.empty?
        return auto_required_gemspecs_from_bundler if require == 'bundler/require'

        gemspecs = all_gemspecs_from_bundler
        # @type [Gem::Specification, nil]
        gemspec = gemspecs.find { |gemspec| gemspec.name == require }
        if gemspec.nil?
          # TODO: this seems hinky
          gem_name_guess = require.split('/').first
          begin
            # this can happen when the gem is included via a local path in
            # a Gemfile; Gem doesn't try to index the paths in that case.
            #
            # See if we can make a good guess:
            potential_gemspec = Gem::Specification.find_by_name(gem_name_guess)

            return nil if potential_gemspec.nil?

            file = "lib/#{require}.rb"
            # @sg-ignore Unresolved call to files
            gemspec = potential_gemspec if potential_gemspec&.files&.any? { |gemspec_file| file == gemspec_file }
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
      # @return [Array<Gem::Specification>]
      def fetch_dependencies gemspec
        gemspecs = all_gemspecs_from_bundler

        # @param spec [Gem::Dependency]
        only_runtime_dependencies(gemspec).each_with_object(Set.new) do |spec, deps|
          Solargraph.logger.info "Adding #{spec.name} dependency for #{gemspec.name}"
          # @type [Gem::Specification, nil]
          dep = gemspecs.find { |dep| dep.name == spec.name }
          # TODO: is next line necessary?
          dep ||= Gem::Specification.find_by_name(spec.name, spec.requirement)
          deps.merge fetch_dependencies(dep) if deps.add?(dep)
        rescue Gem::MissingSpecError
          Solargraph.logger.warn("Gem dependency #{spec.name} #{spec.requirement} " \
                                 "for #{gemspec.name} not found in RubyGems.")
        end.to_a
      end

      private

      # @param command [String] The expression to evaluate in the external bundle
      # @sg-ignore Need a JSON type
      # @yield [undefined]
      def query_external_bundle command, &block
        # TODO: probably combine with logic in require_paths.rb
        Solargraph.with_clean_env do
          cmd = [
            'ruby', '-e',
            "require 'bundler'; require 'json'; Dir.chdir('#{directory}') { puts #{command}.to_json }"
          ]
          # @sg-ignore Unresolved call to capture3
          o, e, s = Open3.capture3(*cmd)
          if s.success?
            Solargraph.logger.debug "External bundle: #{o}"
            data = o && !o.empty? ? JSON.parse(o.split("\n").last) : {}
            block.yield data
          else
            Solargraph.logger.warn e
            raise BundleNotFoundError, "Failed to load gems from bundle at #{directory}"
          end
        end
      end

      # True if the workspace has a root Gemfile.
      #
      # @todo Handle projects with custom Bundler/Gemfile setups (see DocMap#gemspecs_required_from_bundler)
      #
      def gemfile?
        directory && File.file?(File.join(directory, 'Gemfile'))
      end

      def in_this_bundle?
        directory && Bundler.definition&.lockfile&.to_s&.start_with?(directory) # rubocop:disable Style/SafeNavigationChainLength
      end

      # Returns all gemspecs directly depended on by this workspace's
      # bundle (does not include transitive dependencies).
      #
      # @return [Array<Gem::Specification>]
      def all_gemspecs_from_bundler
        @all_gemspecs_from_bundler ||=
          if in_this_bundle?
            all_gemspecs_from_this_bundle
          else
            all_gemspecs_from_external_bundle
          end
      end

      # @return [Array<Gem::Specification>]
      def all_gemspecs_from_this_bundle
        # Find only the gems bundler is now using
        Bundler.definition.locked_gems.specs.map(&:materialize_for_installation)
      end

      # @return [Array<Gem::Specification>]
      def auto_required_gemspecs_from_bundler
        logger.info 'Fetching gemspecs autorequired from Bundler (bundler/require)'
        @auto_required_gemspecs_from_bundler ||=
          if in_this_bundle?
            auto_required_gemspecs_from_this_bundle
          else
            auto_required_gemspecs_from_external_bundle
          end
      end

      # TODO: "Astute readers will notice that the correct way to
      #   require the rack-cache gem is require 'rack/cache', not
      #   require 'rack-cache'. To tell bundler to use require
      #   'rack/cache', update your Gemfile:"
      #
      # gem 'rack-cache', require: 'rack/cache'

      # @return [Array<Gem::Specification>]
      def auto_required_gemspecs_from_this_bundle
        dependencies = Bundler.definition.dependencies

        all_gemspecs_from_bundler.select do |gemspec|
          dependencies.key?(gemspec.name) &&
            dependencies[gemspec.name].autorequire != []
        end
      end

      # @return [Array<Gem::Specification>]
      def auto_required_gemspecs_from_external_bundle
        @auto_required_gemspecs_from_external_bundle ||=
          begin
            logger.info 'Fetching auto-required gemspecs from Bundler (bundler/require)'
            command =
              'dependencies = Bundler.definition.dependencies; ' \
              'all_specs = Bundler.definition.locked_gems.specs; ' \
              'autorequired_specs = all_specs.' \
              'select { |gemspec| dependencies.key?(gemspec.name) && dependencies[gemspec.name].autorequire != [] }; ' \
              'autorequired_specs.map { |spec| [spec.name, spec.version] }'
            query_external_bundle command do |dependencies|
              dependencies.map do |name, requirement|
                resolve_gem_ignoring_local_bundle name, requirement
              end.compact
            end
          end
      end

      # @param gemspec [Gem::Specification]
      # @return [Array<Gem::Dependency>]
      def only_runtime_dependencies gemspec
        gemspec.dependencies - gemspec.development_dependencies
      end

      # @todo Should this be using Gem::SpecFetcher and pull them automatically?
      #
      # @param name [String]
      # @param version [String]
      # @return [Gem::Specification, nil]
      def resolve_gem_ignoring_local_bundle name, version
        Gem::Specification.find_by_name(name, version)
      rescue Gem::MissingSpecError
        begin
          Gem::Specification.find_by_name(name)
        rescue Gem::MissingSpecError
          logger.warn "Please install the gem #{name}:#{version} in Solargraph's Ruby environment"
          nil
        end
      end

      # @return [Array<Gem::Specification>]
      def all_gemspecs_from_external_bundle
        return [] unless directory

        @all_gemspecs_from_external_bundle ||=
          begin
            logger.info 'Fetching gemspecs required from external bundle'

            command = 'Bundler.definition.locked_gems.specs.map { |spec| [spec.name, spec.version] }.to_h'

            query_external_bundle command do |names_and_versions|
              names_and_versions.map do |name, version|
                resolve_gem_ignoring_local_bundle(name, version)
              end.compact
            end
          end
      end

      # @return [Hash{String => Gem::Specification}]
      def preference_map
        @preference_map ||= preferences.to_h { |gemspec| [gemspec.name, gemspec] }
      end

      # @param gemspec [Gem::Specification]
      #
      # @return [Gem::Specification]
      def gemspec_or_preference gemspec
        return gemspec unless preference_map.key?(gemspec.name)
        return gemspec if gemspec.version == preference_map[gemspec.name].version

        change_gemspec_version gemspec, preference_map[gemspec.name].version
      end

      # @param gemspec [Gem::Specification]
      # @param version [String]
      # @return [Gem::Specification]
      def change_gemspec_version gemspec, version
        Gem::Specification.find_by_name(gemspec.name, "= #{version}")
      rescue Gem::MissingSpecError
        Solargraph.logger.info "Gem #{gemspec.name} version #{version} not found. Using #{gemspec.version} instead"
        gemspec
      end
    end
  end
end
