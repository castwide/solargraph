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

        # This is added in the parser when it sees 'Bundler.require' -
        # see https://bundler.io/guides/bundler_setup.html '
        #
        # @todo handle different arguments to Bundler.require
        return auto_required_gemspecs_from_bundler if require == 'bundler/require'

        # Determine gem name based on the require path
        file = "lib/#{require}.rb"
        spec_with_path = Gem::Specification.find_by_path(file)

        all_gemspecs = all_gemspecs_from_bundle

        gem_names_to_try = [
          spec_with_path&.name,
          require.tr('/', '-'),
          require.split('/').first
        ].compact.uniq
        gem_names_to_try.each do |gem_name|
          gemspec = all_gemspecs.find { |gemspec| gemspec.name == gem_name }
          return [gemspec_or_preference(gemspec)] if gemspec

          begin
            gemspec = Gem::Specification.find_by_name(gem_name)
            return [gemspec_or_preference(gemspec)] if gemspec
          rescue Gem::MissingSpecError
            logger.debug do
              "Require path #{require} could not be resolved to a gem via find_by_path or guess of #{gem_name}"
            end
          end

          # look ourselves just in case this is hanging out somewhere
          # that find_by_path doesn't index'
          gemspec = all_gemspecs.find do |spec|
            spec = to_gem_specification(spec) unless spec.respond_to?(:files)

            spec&.files&.any? { |gemspec_file| file == gemspec_file }
          end
          return [gemspec_or_preference(gemspec)] if gemspec
        end

        nil
      end

      # @param stdlib_name [String]
      #
      # @return [Array<String>]
      def stdlib_dependencies stdlib_name
        deps = RbsMap::StdlibMap.stdlib_dependencies(stdlib_name, nil) || []
        deps.map { |dep| dep['name'] }.compact
      end

      # @param name [String]
      # @param version [String, nil]
      # @param out [IO, nil] output stream for logging
      #
      # @return [Gem::Specification, nil]
      def find_gem name, version = nil, out: $stderr
        specish = all_gemspecs_from_bundle.find { |specish| specish.name == name && specish.version == version }
        return to_gem_specification specish if specish

        specish = all_gemspecs_from_bundle.find { |specish| specish.name == name }
        return to_gem_specification specish if specish

        resolve_gem_ignoring_local_bundle name, version, out: out
      end

      # @param gemspec [Gem::Specification]
      # @param out[IO, nil] output stream for logging
      #
      # @return [Array<Gem::Specification>]
      def fetch_dependencies gemspec, out: $stderr
        gemspecs = all_gemspecs_from_bundle

        # @type [Hash{String => Gem::Specification}]
        deps_so_far = {}

        # @param runtime_dep [Gem::Dependency]
        # @param deps [Hash{String => Gem::Specification}]
        gem_dep_gemspecs = only_runtime_dependencies(gemspec).each_with_object(deps_so_far) do |runtime_dep, deps|
          # @sg-ignore Unresolved call to requirement on Gem::Dependency
          dep = find_gem(runtime_dep.name, runtime_dep.requirement)
          next unless dep

          fetch_dependencies(dep, out: out).each { |sub_dep| deps[sub_dep.name] ||= sub_dep }

          deps[dep.name] ||= dep
        end

        # RBS tracks implicit dependencies, like how the YAML standard
        # library implies pulling in the psych library.
        stdlib_deps = RbsMap::StdlibMap.stdlib_dependencies(gemspec.name, gemspec.version) || []
        stdlib_dep_gemspecs = stdlib_deps.map { |dep| find_gem(dep['name'], dep['version']) }.compact
        (gem_dep_gemspecs.values.compact + stdlib_dep_gemspecs).uniq(&:name)
      end

      # Returns all gemspecs directly depended on by this workspace's
      # bundle (does not include transitive dependencies).
      #
      # @return [Array<Gem::Specification, Bundler::LazySpecification, Bundler::StubSpecification>]
      def all_gemspecs_from_bundle
        return [] unless directory

        @all_gemspecs_from_bundle ||=
          if in_this_bundle?
            all_gemspecs_from_this_bundle
          else
            all_gemspecs_from_external_bundle
          end
      end

      # @return [Hash{Gem::Specification, Bundler::LazySpecification, Bundler::StubSpecification => Gem::Specification}]
      def self.gem_specification_cache
        @gem_specification_cache ||= {}
      end

      private

      # @param specish [Gem::Specification, Bundler::LazySpecification, Bundler::StubSpecification]
      #
      # @return [Gem::Specification, nil]
      def to_gem_specification specish
        # print time including milliseconds
        self.class.gem_specification_cache[specish] ||= case specish
                                                        when Gem::Specification
                                                          specish
                                                        when Bundler::LazySpecification
                                                          # materializing didn't work.  Let's look in the local
                                                          # rubygems without bundler's help
                                                          resolve_gem_ignoring_local_bundle specish.name,
                                                                                            specish.version
                                                        when Bundler::StubSpecification
                                                          # turns a Bundler::StubSpecification into a
                                                          # Gem::StubSpecification if we can
                                                          if specish.respond_to?(:stub)
                                                            to_gem_specification specish.stub
                                                          else
                                                            # A Bundler::StubSpecification is a Bundler::
                                                            # RemoteSpecification which ought to proxy a Gem::
                                                            # Specification
                                                            specish
                                                          end
                                                        # @sg-ignore Unresolved constant Gem::StubSpecification
                                                        when Gem::StubSpecification
                                                          specish.to_spec
                                                        else
                                                          raise "Unexpected type while resolving gem: #{specish.class}"
                                                        end
      end

      # @param command [String] The expression to evaluate in the external bundle
      # @sg-ignore Need a JSON type
      # @yield [undefined, nil]
      def query_external_bundle command
        Solargraph.with_clean_env do
          cmd = [
            'ruby', '-e',
            "require 'bundler'; require 'json'; Dir.chdir('#{directory}') { puts begin; #{command}; end.to_json }"
          ]
          o, e, s = Open3.capture3(*cmd)
          if s.success?
            Solargraph.logger.debug "External bundle: #{o}"
            o && !o.empty? ? JSON.parse(o.split("\n").last) : nil
          else
            Solargraph.logger.warn e
            raise BundleNotFoundError, "Failed to load gems from bundle at #{directory}"
          end
        end
      end

      def in_this_bundle?
        Bundler.definition&.lockfile&.to_s&.start_with?(directory)
      end

      # @return [Array<Gem::Specification, Bundler::LazySpecification, Bundler::StubSpecification>]
      def all_gemspecs_from_this_bundle
        # Find only the gems bundler is now using
        specish_objects = Bundler.definition.locked_gems.specs
        if specish_objects.first.respond_to?(:materialize_for_installation)
          specish_objects = specish_objects.map(&:materialize_for_installation)
        end
        specish_objects.map do |specish|
          if specish.respond_to?(:name) && specish.respond_to?(:version) && specish.respond_to?(:gem_dir)
            # duck type is good enough for outside uses!
            specish
          else
            to_gem_specification(specish)
          end
        end.compact
      end

      # @return [Array<Gem::Specification, Bundler::LazySpecification, Bundler::StubSpecification>]
      def auto_required_gemspecs_from_bundler
        return [] unless directory

        logger.info 'Fetching gemspecs autorequired from Bundler (bundler/require)'
        @auto_required_gemspecs_from_bundler ||=
          if in_this_bundle?
            auto_required_gemspecs_from_this_bundle
          else
            auto_required_gemspecs_from_external_bundle
          end
      end

      # @return [Array<Gem::Specification, Bundler::LazySpecification, Bundler::StubSpecification>]
      def auto_required_gemspecs_from_this_bundle
        # Adapted from require() in lib/bundler/runtime.rb
        dep_names = Bundler.definition.dependencies.select do |dep|
          dep.groups.include?(:default) && dep.should_include?
        end.map(&:name)

        all_gemspecs_from_bundle.select { |gemspec| dep_names.include?(gemspec.name) }
      end

      # @return [Array<Gem::Specification, Bundler::LazySpecification, Bundler::StubSpecification>]
      def auto_required_gemspecs_from_external_bundle
        @auto_required_gemspecs_from_external_bundle ||=
          begin
            logger.info 'Fetching auto-required gemspecs from Bundler (bundler/require)'
            command =
              'Bundler.definition.dependencies' \
              '.select { |dep| dep.groups.include?(:default) && dep.should_include? }' \
              '.map(&:name)'
            # @sg-ignore
            # @type [Array<String>]
            dep_names = query_external_bundle command

            all_gemspecs_from_bundle.select { |gemspec| dep_names.include?(gemspec.name) }
          end
      end

      # @param gemspec [Gem::Specification]
      # @return [Array<Gem::Dependency>]
      def only_runtime_dependencies gemspec
        unless gemspec.respond_to?(:dependencies) && gemspec.respond_to?(:development_dependencies)
          gemspec = to_gem_specification(gemspec)
        end
        return [] if gemspec.nil?

        gemspec.dependencies - gemspec.development_dependencies
      end

      # @todo Should this be using Gem::SpecFetcher and pull them automatically?
      #
      # @param name [String]
      # @param version_or_requirement [String, nil]
      # @param out [IO, nil] output stream for logging
      #
      # @return [Gem::Specification, nil]
      def resolve_gem_ignoring_local_bundle name, version_or_requirement = nil, out: $stderr
        Gem::Specification.find_by_name(name, version_or_requirement)
      rescue Gem::MissingSpecError
        begin
          Gem::Specification.find_by_name(name)
        rescue Gem::MissingSpecError
          stdlibmap = RbsMap::StdlibMap.new(name)
          unless stdlibmap.resolved?
            gem_desc = name
            gem_desc += ":#{version_or_requirement}" if version_or_requirement
            out&.puts "Please install the gem #{gem_desc} in Solargraph's Ruby environment"
          end
          nil # either not here or in stdlib
        end
      end

      # @return [Array<Gem::Specification>]
      def all_gemspecs_from_external_bundle
        @all_gemspecs_from_external_bundle ||=
          begin
            logger.info 'Fetching gemspecs required from external bundle'

            command = 'specish_objects = Bundler.definition.locked_gems&.specs; ' \
                      'if specish_objects.first.respond_to?(:materialize_for_installation);' \
                      'specish_objects = specish_objects.map(&:materialize_for_installation);' \
                      'end;' \
                      'specish_objects.map { |specish| [specish.name, specish.version] }'
            # @type [Array<Gem::Specification>]
            query_external_bundle(command).map do |name, version|
              resolve_gem_ignoring_local_bundle(name, version)
            end.compact
          rescue Solargraph::BundleNotFoundError => e
            Solargraph.logger.info e.message
            Solargraph.logger.debug e.backtrace.join("\n")
            []
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
        Solargraph.logger.info "Gem #{gemspec.name} version #{version.inspect} not found. " \
                               "Using #{gemspec.version} instead"
        gemspec
      end
    end
  end
end
