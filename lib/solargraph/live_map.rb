module Solargraph
  class LiveMap
    def refresh workspace, required
      # HACK: Testing inclusion of rails for use in live_map
      if required.include?('rails/all')
        STDERR.puts "REFRESHING LIVE!!!!!"
        rails_config = File.join(workspace, 'config', 'environment.rb')
        if File.file?(rails_config)
          unless require_relative(rails_config)
            Rails.application.reloader.reload!
          end
        end
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
