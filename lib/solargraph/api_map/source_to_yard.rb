module Solargraph
  class ApiMap
    module SourceToYard

      # Get the YARD CodeObject at the specified path.
      #
      # @return [YARD::CodeObjects::Base]
      def code_object_at path
        code_object_map[path]
      end

      def code_object_paths
        code_object_map.keys
      end

      private

      def code_object_map
        @code_object_map ||= {}
      end

      def rake_yard sources
        code_object_map.clear
        sources.each do |s|
          s.namespace_pins.each do |pin|
            if pin.kind == :class
              code_object_map[pin.path] ||= YARD::CodeObjects::ClassObject.new(code_object_at(pin.namespace), pin.name)
            else
              code_object_map[pin.path] ||= YARD::CodeObjects::ModuleObject.new(code_object_at(pin.namespace), pin.name)
            end
            code_object_map[pin.path].docstring = pin.docstring unless pin.docstring.nil?
          end
          s.method_pins.each do |pin|
            code_object_map[pin.path] ||= YARD::CodeObjects::MethodObject.new(code_object_at(pin.namespace), pin.name, pin.scope)
            code_object_map[pin.path].docstring = pin.docstring unless pin.docstring.nil?
            code_object_map[pin.path].parameters = pin.parameters.map do |p|
              n = p.match(/^[a-z0-9\-]*?:?/i)[0]
              v = nil
              if p.length > n.length
                v = p[n.length..-1].gsub(/^ = /, '')
              end
              [n, v]
            end
          end
        end
      end
    end
  end
end
