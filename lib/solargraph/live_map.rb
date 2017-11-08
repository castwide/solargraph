module Solargraph
  # The LiveMap allows extensions to add their own completion suggestions.
  #
  class LiveMap
    @@plugins = []

    # @return [Solargraph::ApiMap]
    attr_reader :api_map

    def initialize api_map
      @api_map = api_map
      @runners = []
      at_exit { stop }
    end

    def start
      unless api_map.workspace.nil?
        @@plugins.each do |p|
          r = p.new(api_map)
          r.start
          @runners.push r
        end
      end
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

    def get_instance_methods(namespace, root = '', with_private = false)
      result = []
      @runners.each do |p|
        resp = p.get_methods(namespace: namespace, root: root, scope: 'instance', with_private: with_private)
        STDERR.puts resp.message unless resp.ok?
        result.concat(resp.data)
      end
      result
    end

    def get_methods(namespace, root = '', with_private = false)
      result = []
      @runners.each do |p|
        resp = p.get_methods(namespace: namespace, root: root, scope: 'class', with_private: with_private)
        STDERR.puts resp.message unless resp.ok?
        result.concat(resp.data)
      end
      result
    end

    def self.install cls
      @@plugins.push cls
    end

    private

    def find_constant(namespace, root)
      result = nil
      parts = root.split('::')
      if parts.empty?
        result = inner_find_constant(namespace)
      else
        until parts.empty?
          result = inner_find_constant("#{parts.join('::')}::#{namespace}")
          break unless result.nil?
          parts.pop
        end
      end
      result
    end

    def inner_find_constant(namespace)
      cursor = Object
      parts = namespace.split('::')
      until parts.empty?
        here = parts.shift
        begin
          cursor = cursor.const_get(here)
        rescue NameError
          return nil
        end
      end
      cursor
    end
  end
end
