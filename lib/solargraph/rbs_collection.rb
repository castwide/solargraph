# frozen_string_literal: true

module Solargraph
  class RbsCollection
    attr_reader :lockfile

    def initialize lockfile
      @lockfile = File.expand_path(lockfile) if lockfile
    end

    # @param metagem [Metagem]
    # @return [Array<Pin::Base>]
    def load metagem
      key = best_key(metagem)
      return [] unless key
      mem_cache[key] ||= RbsMap::Path.pins(gem_path_map[key])
    end

    def gem_keys
      gem_path_map.keys
    end

    private

    def gem_path_map
      @gem_path_map ||= raw_data[:gems].to_h { |gem| ["#{gem[:name]}-#{gem[:version]}", gem_source_path(gem)] }
    end

    def best_key metagem
      key = "#{metagem.name}-#{metagem.version}"
      return key if gem_path_map.key?(key)

      full_key = "#{metagem.name}-#{metagem.version}."
      zero_key = "#{metagem.name}-0"
      found = gem_path_map.find { |key, _| full_key.start_with?("#{key}.") } ||
              gem_path_map.find { |key, _| key == zero_key }
      found&.first
    end

    # @param gem_hash [Hash]
    def gem_source_path gem_hash
      root_path = gem_hash.dig(:source, :path) || raw_data[:path]
      return unless root_path
      gem_path = File.join(root_path, gem_hash[:name], gem_hash[:version])
      File.expand_path(gem_path, File.dirname(lockfile))
    end

    def gem_rbs_collection_path
      @gem_rbs_collection_path ||= File.expand_path(raw_data[:path]) if raw_data[:path]
    end

    # @return [Hash]
    def raw_data
      @raw_data ||= if lockfile && File.file?(lockfile)
                      YAML.load_file(lockfile, symbolize_names: true)
                    else
                      { gems: [] }
                    end
    end

    def mem_cache
      @mem_cache ||= {}
    end
  end
end
