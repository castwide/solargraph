module Solargraph
  # The LiveMap allows extensions to add their own completion suggestions.
  #
  class LiveMap
    autoload :Cache, 'solargraph/live_map/cache'

    @@plugins = []

    # @return [Solargraph::ApiMap]
    attr_reader :api_map

    def initialize api_map
      @api_map = api_map
      runners
    end

    def get_methods(namespace, root = '', scope = 'instance', with_private = false)
      params = {
        namespace: namespace, root: root, scope: scope, with_private: with_private
      }
      cached = cache.get_methods(params)
      return cached unless cached.nil?
      did_runtime = false
      result = []
      runners.each do |p|
        next if did_runtime and p.runtime?
        result.concat p.get_methods(namespace: namespace, root: root, scope: scope, with_private: with_private)
        did_runtime = true if p.runtime?
      end
      cache.set_methods(params, result)
      result
    end

    def get_constants(namespace, root = '')
      cached = cache.get_constants(namespace, root)
      return cached unless cached.nil?
      did_runtime = false
      result = []
      runners.each do |p|
        next if did_runtime and p.runtime?
        result.concat p.get_constants(namespace, root)
        did_runtime = true if p.runtime?
      end
      cache.set_constants(namespace, root, result)
      result
    end

    def get_fqns(namespace, root)
      did_runtime = false
      runners.each do |p|
        next if did_runtime and p.runtime?
        result = p.get_fqns(namespace, root)
        return result unless result.nil?
        did_runtime = true if p.runtime?
      end
      nil
    end

    # Register a plugin for LiveMap to use when generating suggestions.
    #
    # @param cls [Class<Solargraph::Plugin::Base>]
    def self.install cls
      @@plugins.push cls unless @@plugins.include?(cls)
    end

    def self.uninstall cls
      @@plugins.delete cls
    end

    def self.plugins
      @@plugins.clone
    end

    def refresh
      changed = false
      runners.each do |p|
        changed ||= p.refresh
      end
      cache.clear if changed
    end

    private

    # @return [Solargraph::LiveMap::Cache]
    def cache
      @cache ||= Solargraph::LiveMap::Cache.new
    end

    # @return [Array<Solargraph::Plugin::Base>]
    def runners
      @runners ||= load_runners
    end

    # @return [Array<Solargraph::Plugin::Base>]
    def load_runners
      result = []
      has_runtime = false
      @@plugins.each do |p|
        r = p.new(api_map)
        result.push r if !has_runtime or !r.runtime?
        has_runtime = true if r.runtime?
      end
      result.push Solargraph::Plugin::Runtime.new(api_map) unless has_runtime
      result
    end
  end
end
