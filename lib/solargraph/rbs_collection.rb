# frozen_string_literal: true

module Solargraph
  # The RBS collection declared by a project's rbs_collection.lock.yaml.
  #
  class RbsCollection
    attr_reader :lockfile

    # @param lockfile [String, nil]
    def initialize lockfile
      @lockfile = File.expand_path(lockfile) if lockfile
    end

    # @param metagem [Metagem]
    # @return [Array<Pin::Base>]
    def load metagem
      key = best_key(metagem)
      return [] unless key
      # @sg-ignore Skip collection gems that have no source path
      mem_cache[key] ||= RbsMap::Path.pins(gem_path_map[key])
    end

    # @return [Array<String>]
    def gem_keys
      gem_path_map.keys
    end

    # The names of the stdlib signature sets declared by the collection.
    #
    # +rbs collection install+ resolves these to the signatures which ship
    # with the rbs gem instead of copying them into the collection directory,
    # so they can never be located by a gem name/version lookup.
    #
    # @return [Array<String>]
    # @sg-ignore Library method has no usable type
    def stdlib_names
      @stdlib_names ||= raw_data[:gems].select { |gem| gem.dig(:source, :type).to_s == 'stdlib' }
                                       # @sg-ignore Library method has no usable type
                                       .map { |gem| gem[:name].to_s }.uniq
    end

    private

    # @return [Hash{String => String, nil}]
    # @sg-ignore Library method has no usable type
    def gem_path_map
      # @sg-ignore Library method has no usable type
      @gem_path_map ||= raw_data[:gems].to_h { |gem| ["#{gem[:name]}-#{gem[:version]}", gem_source_path(gem)] }
    end

    # The versions available in the collection for each gem name.
    #
    # @return [Hash{String => Array<String>}]
    # @sg-ignore Library method has no usable type
    def versions_by_name
      @versions_by_name ||= raw_data[:gems].group_by { |gem| gem[:name].to_s }
                                           # @sg-ignore Library method has no usable type
                                           .transform_values { |gems| gems.map { |gem| gem[:version].to_s } }
    end

    # @param metagem [Metagem]
    # @return [String, nil]
    # @sg-ignore Accept NilClass where nil is declared
    def best_key metagem
      key = "#{metagem.name}-#{metagem.version}"
      return key if gem_path_map.key?(key)

      full_key = "#{metagem.name}-#{metagem.version}."
      zero_key = "#{metagem.name}-0"
      found = gem_path_map.find { |key, _| full_key.start_with?("#{key}.") } ||
              # @sg-ignore https://github.com/castwide/solargraph/pull/1231
              gem_path_map.find { |key, _| key == zero_key }
      found&.first || closest_key(metagem)
    end

    # Signature collections version their directories independently from the
    # gems they describe. gem_rbs_collection, for example, provides
    # +actionpack/6.0+ for every Rails 6 and 7 release and +devise/4.9+ for
    # Devise 4 and 5. When no directory matches a gem's version, fall back to
    # the closest version the collection provides for that gem, preferring the
    # highest one that does not exceed the gem's version.
    #
    # @param metagem [Metagem]
    # @return [String, nil]
    def closest_key metagem
      versions = versions_by_name[metagem.name.to_s]
      return nil if versions.nil? || versions.empty?
      return "#{metagem.name}-#{versions.first}" if versions.size == 1
      parsed = versions.map { |version| [version, parse_version(version)] }
      usable = parsed.compact
      gem_version = parse_version(metagem.version)
      chosen = if gem_version
                 usable.reject { |_, parsed_version| parsed_version > gem_version }.max_by { |_, parsed_version| parsed_version }
               end
      chosen ||= usable.min_by { |_, parsed_version| parsed_version }
      chosen ||= parsed.first
      # @sg-ignore Library method has no usable type
      "#{metagem.name}-#{chosen[0]}"
    end

    # @param value [Object]
    # @return [Gem::Version, nil]
    def parse_version value
      Gem::Version.new value.to_s
    rescue ArgumentError
      nil
    end

    # @param gem_hash [Hash]
    # @return [String, nil]
    def gem_source_path gem_hash
      root_path = gem_hash.dig(:source, :path) || raw_data[:path]
      return unless root_path
      gem_path = File.join(root_path, gem_hash[:name], gem_hash[:version])
      File.expand_path(gem_path, File.dirname(lockfile))
    end

    # @return [String, nil]
    def gem_rbs_collection_path
      @gem_rbs_collection_path ||= File.expand_path(raw_data[:path]) if raw_data[:path]
    end

    # @return [Hash]
    # @sg-ignore Library method has no usable type
    def raw_data
      @raw_data ||= if lockfile && File.file?(lockfile)
                      YAML.load_file(lockfile, symbolize_names: true)
                    else
                      { gems: [] }
                    end
    end

    # @return [Hash{String => Array<Pin::Base>}]
    def mem_cache
      @mem_cache ||= {}
    end
  end
end
