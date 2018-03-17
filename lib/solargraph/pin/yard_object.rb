module Solargraph
  module Pin
    class YardObject < Base
      # @return [YARD::CodeObjects::Base]
      attr_reader :code_object

      def initialize code_object
        # (c.to_s.split('::').last, detail: c.to_s, kind: kind, docstring: c.docstring, return_type: return_type, location: object_location(c))
        @code_object = code_object
      end

      def name
        # @name ||= code_object.to_s.split('::').last
        @name ||= code_object.name.to_s
      end

      def kind
        # @todo Figure out the kind
      end

      def docstring
        code_object.docstring
      end

      def return_type
        # @todo Get the return type
        return nil if docstring.nil?
        tags = docstring.tags(:return)
        if tags.empty?
          overload = docstring.tag(:overload)
          return nil if overload.nil?
          tags = overload.tags(:return)
        end
        return nil if tags.empty?
        return nil if tags[0].types.nil?
        return tags[0].types[0]
      end

      def location
        # @todo Get the location
      end

      def path
        code_object.path
      end
      
      def namespace
        # @todo Is this right?
        code_object.namespace.to_s
      end
    end
  end
end
