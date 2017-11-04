module Solargraph
  class LiveMap
    @@plugins = []
    
    attr_reader :workspace

    def initialize workspace
      @workspace = workspace
      @runners = []
      open
    end

    def open
      unless workspace.nil?
        @@plugins.each do |p|
          @runners.push p.new(workspace)
        end
      end
    end

    def reload
      close
      open
    end

    def close
      @runners.each do |p|
        p.close
      end
      @runners.clear
    end

    def get_public_instance_methods(namespace, root = '')
      result = []
      @runners.each do |p|
        result.concat(p.query('instance', namespace, root))
      end
      result
    end

    def get_public_methods(namespace, root = '')
      result = []
      @runners.each do |p|
        result.concat(p.query('class', namespace, root))
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
