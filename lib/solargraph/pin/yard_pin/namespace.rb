module Solargraph
  module Pin
    module YardPin
      class Namespace < Pin::Namespace
        include YardMixin

        def initialize code_object, location
          superclass = nil
          # @todo This method of superclass detection is a bit of a hack. If
          #   the superclass is a Proxy, it is assumed to be undefined in its
          #   yardoc and converted to a fully qualified namespace.
          if code_object.is_a?(YARD::CodeObjects::ClassObject) && code_object.superclass
            if code_object.superclass.is_a?(YARD::CodeObjects::Proxy)
              superclass = "::#{code_object.superclass}"
            else
              superclass = code_object.superclass.to_s
            end
          end
          super(location, code_object.namespace.to_s, code_object.name.to_s, comments_from(code_object), namespace_type(code_object), code_object.visibility, superclass)
          code_object.class_mixins.each do |m|
            extend_references.push Pin::Reference.new(location, path, m.path)
          end
          code_object.instance_mixins.each do |m|
            include_references.push Pin::Reference.new(location, path, m.path)
          end
        end

        private

        def namespace_type code_object
          code_object.is_a?(YARD::CodeObjects::ClassObject) ? :class : :module
        end
      end
    end
  end
end
