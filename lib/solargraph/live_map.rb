module Solargraph
  # The LiveMap allows extensions to add their own completion suggestions.
  #
  class LiveMap
    autoload :Cache, 'solargraph/live_map/cache'

    @@plugin_registry = {}

    # @return [Solargraph::ApiMap]
    attr_reader :api_map

    # @param api_map [Solargraph::ApiMap]
    def initialize api_map
      @api_map = api_map
      runners
    end

    def get_path_pin path
      cache.get_path_pin(path)
    end

    # @return [Array<Solargraph::Pin::Base>]
    def get_methods(namespace, root = '', scope = 'instance', with_private = false)
      fqns = api_map.qualify(namespace, root)
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
          result.push Solargraph::Pin::Method.new(nil, namespace, m['name'], YARD::Docstring.new('(defined at runtime)'), scope.to_sym, nil, [])
        end
        did_runtime = true if p.runtime?
      end
      cache.set_methods(params, result)
      result
    end

    # @return [Array<Solargraph::Pin::Base>]
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
        kind = Pin::CONSTANT
        if r['class'] == 'Class'
          suggestions.push Pin::Namespace.new(nil, r['namespace'], r['name'], YARD::Docstring.new("(defined at runtime)"), :class, :public, nil)
        elsif r['class'] == 'Module'
          suggestions.push Pin::Namespace.new(nil, r['namespace'], r['name'], YARD::Docstring.new("(defined at runtime)"), :module, :public, nil)
        else
          suggestions.push Pin::Constant.new(nil, r['namespace'], r['name'], YARD::Docstring.new("(defined at runtime"), nil, nil, nil, :public)
        end
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

    def refresh
      changed = false
      runners.each do |p|
        changed ||= p.refresh
      end
      if changed
        Solargraph::Logging.logger.debug "Resetting LiveMap cache"
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
      api_map.workspace.config.plugins.each do |name|
        r = @@plugin_registry[name].new(api_map)
        result.push r
      end
      result
    end
  end
end

Solargraph::LiveMap.register 'runtime', Solargraph::Plugin::Runtime
