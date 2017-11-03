module Solargraph
  class LiveMap
    def get_public_instance_methods(namespace, root = '')
      con = find_constant(namespace, root)
      return [] if con.nil?
      con.public_instance_methods.map(&:to_s)
    end

    def get_public_methods(namespace, root = '')
      con = find_constant(namespace, root)
      return [] if con.nil?
      con.public_methods.map(&:to_s)
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
