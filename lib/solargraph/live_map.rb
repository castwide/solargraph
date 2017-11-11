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
      @runners = []
    end

    def start
      @@plugins.each do |p|
        r = p.new(api_map)
        r.start
        @runners.push r
      end
      r = Solargraph::Plugin::Runtime.new(api_map)
      r.start
      @runners.push r
    end

    def reload
      restart
    end

    def restart
      stop
      start
    end

    def stop
      @runners.each do |p|
        p.stop
      end
      @runners.clear
    end

    def get_methods(namespace, root = '', scope = 'instance', with_private = false)
      params = {
        namespace: namespace, root: root, scope: scope, with_private: with_private
      }
      cached = cache.get_methods(params)
      return cached unless cached.nil?
      did_runtime = false
      result = []
      @runners.each do |p|
        next if did_runtime and p.runtime?
        resp = p.get_methods(namespace: namespace, root: root, scope: scope, with_private: with_private)
        STDERR.puts resp.message unless resp.ok?
        result.concat(resp.data)
        did_runtime = true if p.runtime?
      end
      cache.set_methods(params, result)
      result
    end

    # Register a plugin for LiveMap to use when generating suggestions.
    #
    # @param cls [Class<Solargraph::Plugin::Base>]
    def self.install cls
      @@plugins.push cls
    end

    private

    # @return [Solargraph::LiveMap::Cache]
    def cache
      @cache ||= Solargraph::LiveMap::Cache.new
    end
  end
end
