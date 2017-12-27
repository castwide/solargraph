module Solargraph
  class ApiMap
    module SourceToYard

      private

      # Get the YARD CodeObject at the specified path.
      #
      # @return [YARD::CodeObjects::Base]
      def code_object_at path
        code_object_map[path]
      end

      def code_object_paths
        code_object_map.keys
      end

      def code_object_map
        @code_object_map ||= {}
      end

      def root_code_object
        @root_code_object ||= YARD::CodeObjects::RootObject.new(nil, 'root')
      end

      def rake_yard sources
        code_object_map.clear
        sources.each do |s|
          s.namespace_pins.each do |pin|
            if pin.kind == Solargraph::Suggestion::CLASS
              code_object_map[pin.path] ||= YARD::CodeObjects::ClassObject.new(root_code_object, pin.path)
            else
              code_object_map[pin.path] ||= YARD::CodeObjects::ModuleObject.new(root_code_object, pin.path)
            end
            code_object_map[pin.path].docstring = pin.docstring unless pin.docstring.nil?
            code_object_map[pin.path].files.push pin.source.filename
          end
          s.namespace_includes.each_pair do |n, i|
            code_object_map[n].mixins.push code_object_map[i] unless code_object_map[i].nil?
          end
          s.attribute_pins.each do |pin|
            code_object_map[pin.path] ||= YARD::CodeObjects::MethodObject.new(code_object_at(pin.namespace), pin.name, :instance)
            code_object_map[pin.path].docstring = pin.docstring unless pin.docstring.nil?
            code_object_map[pin.path].files.push pin.source.filename
            #code_object_map[pin.path].parameters = []
          end
          s.method_pins.each do |pin|
            code_object_map[pin.path] ||= YARD::CodeObjects::MethodObject.new(code_object_at(pin.namespace), pin.name, pin.scope)
            code_object_map[pin.path].docstring = pin.docstring unless pin.docstring.nil?
            code_object_map[pin.path].files.push pin.source.filename
            code_object_map[pin.path].parameters = pin.parameters.map do |p|
              n = p.match(/^[a-z0-9_]*:?/i)[0]
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
