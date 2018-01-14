module Solargraph
  # The LiveMap allows extensions to add their own completion suggestions.
  #
  class LiveMap
    autoload :Cache, 'solargraph/live_map/cache'

    @@plugin_registry = {}

    # @return [Solargraph::ApiMap]
    attr_reader :api_map

    def initialize api_map
      @api_map = api_map
      runners
    end

    def get_methods(namespace, root = '', scope = 'instance', with_private = false)
      fqns = api_map.find_fully_qualified_namespace(namespace, root)
      params = {
        namespace: namespace, root: root, scope: scope, with_private: with_private
      }
      cached = cache.get_methods(params)
      return cached unless cached.nil?
      did_runtime = false
      result = []
      runners.each do |p|
        next if did_runtime and p.runtime?
        p.get_methods(namespace: namespace, root: root, scope: scope, with_private: with_private).each do |m|
          result.push Suggestion.new(m['name'], kind: Suggestion::METHOD, docstring: YARD::Docstring.new('(defined at runtime)'), path: "#{fqns}.#{m['name']}", arguments: m['parameters'])
        end
        did_runtime = true if p.runtime?
      end
      cache.set_methods(params, result)
      result
    end

    # @return [Array<Solargraph::Suggestion>]
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
      suggestions = []
      result.uniq.each do |r|
        path = (r['namespace'].empty? ? '' : "#{r['namespace']}::") + r['name']
        kind = Suggestion::CONSTANT
        if r['class'] == 'Class'
          kind = Suggestion::CLASS
        elsif r['class'] == 'Module'
          kind = Suggestion::MODULE
        end
        suggestions.push(Suggestion.new(r['name'], kind: kind, path: path))
      end
      cache.set_constants(namespace, root, suggestions)
      suggestions
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

    def self.register name, klass
      raise ArgumentError.new("A Solargraph plugin named #{name} already exists") if @@plugin_registry.has_key?(name)
      @@plugin_registry[name] = klass
    end

    # Register a plugin for LiveMap to use when generating suggestions.
    # @deprecated See Solargraph::LiveMap.register instead
    #
    # @param cls [Class<Solargraph::Plugin::Base>]
    def self.install cls
      STDERR.puts "WARNING: The Solargraph::LiveMap.install procedure for installing plugins is no longer used. This operation will be ignored."
    end

    # @deprecated
    def self.uninstall cls
      STDERR.puts "WARNING: The Solargraph::LiveMap.uninstall procedure for uninstalling plugins is no longer used. This operation will be ignored."
    end

    # @deprecated
    def self.plugins
      STDERR.puts "WARNING: Plugins have changed. The Solargraph::LiveMap.plugins attribute is no longer used."
      []
    end

    def refresh
      changed = false
      runners.each do |p|
        changed ||= p.refresh
      end
      if changed
        STDERR.puts "Resetting LiveMap cache"
        cache.clear
        get_constants('')
        get_methods('', '', 'class')
        get_methods('', '', 'instance')
        get_methods('Kernel', '', 'class')
        get_methods('Kernel', '', 'instance')
      end
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
      api_map.config.plugins.each do |name|
        r = @@plugin_registry[name].new(api_map)
        result.push r
      end
      result
    end
  end
end

Solargraph::LiveMap.register 'runtime', Solargraph::Plugin::Runtime
