module Solargraph
  class LiveMap
    @@update_procs = []
    
    # @param api_map [Solargraph::ApiMap]
    def update api_map
      STDERR.puts "************* UPDATING THE LIVE MAP DAMMIT"
      @@update_procs.each do |p|
        p.call(api_map)
      end
    end

    def get_public_instance_methods(namespace, root = '')
      return [] if (namespace.nil? or namespace.empty?) and (root.nil? or root.empty?)
      con = find_constant(namespace, root)
      return [] if con.nil?
      con.public_instance_methods.map(&:to_s)
    end

    def get_public_methods(namespace, root = '')
      return [] if (namespace.nil? or namespace.empty?) and (root.nil? or root.empty?)
      con = find_constant(namespace, root)
      return [] if con.nil?
      con.public_methods.map(&:to_s)
    end

    class << self
      def on_update &proc
        @@update_procs.push proc
      end
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
