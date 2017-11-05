module Solargraph
  # The LiveMap allows extensions to add their own completion suggestions.
  #
  class LiveMap
    @@plugins = []
    
    attr_reader :workspace

    def initialize workspace
      @workspace = workspace
      @runners = []
      at_exit { stop }
      start
    end

    def start
      unless workspace.nil?
        @@plugins.each do |p|
          r = p.new(workspace)
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
        result.concat(p.query(namespace, root, 'instance', with_private ? 'private' : 'public'))
      end
      result
    end

    def get_methods(namespace, root = '', with_private = false)
      result = []
      @runners.each do |p|
        result.concat(p.query(namespace, root, 'class', with_private ? 'private' : 'public'))
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
