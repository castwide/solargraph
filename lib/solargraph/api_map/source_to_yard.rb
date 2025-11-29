# frozen_string_literal: true

module Solargraph
  class ApiMap
    module SourceToYard

      # Get the YARD CodeObject at the specified path.
      #
      # @sg-ignore Declared return type generic<T>, nil does not match
      #   inferred type ::YARD::CodeObjects::Base, nil for
      #   Solargraph::ApiMap::SourceToYard#code_object_at
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
            # @param obj [YARD::CodeObjects::RootObject]
            code_object_map[pin.path] ||= YARD::CodeObjects::ClassObject.new(root_code_object, pin.path) { |obj|
              # @sg-ignore flow sensitive typing needs to handle attrs
              next if pin.location.nil? || pin.location.filename.nil?
              # @sg-ignore flow sensitive typing needs to handle attrs
              obj.add_file(pin.location.filename, pin.location.range.start.line, !pin.comments.empty?)
            }
          else
            # @param obj [YARD::CodeObjects::RootObject]
            code_object_map[pin.path] ||= YARD::CodeObjects::ModuleObject.new(root_code_object, pin.path) { |obj|
              # @sg-ignore flow sensitive typing needs to handle attrs
              next if pin.location.nil? || pin.location.filename.nil?
              # @sg-ignore flow sensitive typing needs to handle attrs
              obj.add_file(pin.location.filename, pin.location.range.start.line, !pin.comments.empty?)
            }
          end
          code_object_map[pin.path].docstring = pin.docstring
          store.get_includes(pin.path).each do |ref|
            include_object = code_object_at(pin.path, YARD::CodeObjects::ClassObject)
            unless include_object.nil? || include_object.nil?
              include_object.instance_mixins.push code_object_map[ref.type.to_s]
            end
          end
          store.get_extends(pin.path).each do |ref|
            extend_object = code_object_at(pin.path, YARD::CodeObjects::ClassObject)
            next unless extend_object
            code_object = code_object_map[ref.type.to_s]
            next unless code_object
            extend_object.class_mixins.push code_object
            extend_object.instance_mixins.push code_object
          end
        end
        store.method_pins.each do |pin|
          if pin.code_object
            code_object_map[pin.path] ||= pin.code_object
            next
          end

          # @sg-ignore Need to add nil check here
          # @param obj [YARD::CodeObjects::RootObject]
          code_object_map[pin.path] ||= YARD::CodeObjects::MethodObject.new(code_object_at(pin.namespace, YARD::CodeObjects::NamespaceObject), pin.name, pin.scope) { |obj|
            # @sg-ignore flow sensitive typing needs to handle attrs
            next if pin.location.nil? || pin.location.filename.nil?
            # @sg-ignore flow sensitive typing needs to handle attrs
            obj.add_file pin.location.filename, pin.location.range.start.line
          }
          method_object = code_object_at(pin.path, YARD::CodeObjects::MethodObject)
          # @sg-ignore Need to add nil check here
          method_object.docstring = pin.docstring
          # @sg-ignore Need to add nil check here
          method_object.visibility = pin.visibility || :public
          # @sg-ignore Need to add nil check here
          method_object.parameters = pin.parameters.map do |p|
            [p.full_name, p.asgn_code]
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
