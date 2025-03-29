# frozen_string_literal: true

module Solargraph
  class ApiMap
    module SourceToYard

      # Get the YARD CodeObject at the specified path.
      #
      # @generic T
      # @param path [String]
      # @param klass [Class<generic<T>>]
      # @return [generic<T>, nil]
      def code_object_at path, klass = YARD::CodeObjects::Base
        obj = code_object_map[path]
        obj if obj&.is_a?(klass)
      end

      # @return [Array<String>]
      def code_object_paths
        code_object_map.keys
      end

      # @param store [ApiMap::Store] ApiMap pin store
      # @return [void]
      def rake_yard store
        YARD::Registry.clear
        code_object_map.clear
        store.namespace_pins.each do |pin|
          next if pin.path.nil? || pin.path.empty?
          if pin.code_object
            code_object_map[pin.path] ||= pin.code_object
            next
          end
          if pin.type == :class
            code_object_map[pin.path] ||= YARD::CodeObjects::ClassObject.new(root_code_object, pin.path) { |obj|
              next if pin.location.nil? || pin.location.filename.nil?
              obj.add_file(pin.location.filename, pin.location.range.start.line, !pin.comments.empty?)
            }
          else
            code_object_map[pin.path] ||= YARD::CodeObjects::ModuleObject.new(root_code_object, pin.path) { |obj|
              next if pin.location.nil? || pin.location.filename.nil?
              obj.add_file(pin.location.filename, pin.location.range.start.line, !pin.comments.empty?)
            }
          end
          code_object_map[pin.path].docstring = pin.docstring
          store.get_includes(pin.path).each do |ref|
            include_object = code_object_at(pin.path, YARD::CodeObjects::ClassObject)
            include_object.instance_mixins.push code_object_map[ref] unless include_object.nil? or include_object.nil?
          end
          store.get_extends(pin.path).each do |ref|
            extend_object = code_object_at(pin.path, YARD::CodeObjects::ClassObject)
            extend_object.instance_mixins.push code_object_map[ref] unless extend_object.nil? or extend_object.nil?
            extend_object.class_mixins.push code_object_map[ref] unless extend_object.nil? or extend_object.nil?
          end
        end
        store.method_pins.each do |pin|
          if pin.code_object
            code_object_map[pin.path] ||= pin.code_object
            next
          end

          code_object_map[pin.path] ||= YARD::CodeObjects::MethodObject.new(code_object_at(pin.namespace, YARD::CodeObjects::NamespaceObject), pin.name, pin.scope) { |obj|
            next if pin.location.nil? || pin.location.filename.nil?
            obj.add_file pin.location.filename, pin.location.range.start.line
          }
          method_object = code_object_at(pin.path, YARD::CodeObjects::MethodObject)
          method_object.docstring = pin.docstring
          method_object.visibility = pin.visibility || :public
          method_object.parameters = pin.parameters.map do |p|
            [p.name, p.asgn_code]
          end
        end
      end

      private

      # @return [Hash{String => YARD::CodeObjects::Base}]
      def code_object_map
        @code_object_map ||= {}
      end

      # @return [YARD::CodeObjects::RootObject]
      def root_code_object
        @root_code_object ||= YARD::CodeObjects::RootObject.new(nil, 'root')
      end
    end
  end
end
