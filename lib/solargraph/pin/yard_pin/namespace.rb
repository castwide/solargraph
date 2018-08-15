module Solargraph
  module Pin
    module YardPin
      class Namespace < Pin::Namespace
        include YardMixin

        def initialize code_object, location
          superclass = nil
          superclass = code_object.superclass.to_s if code_object.is_a?(YARD::CodeObjects::ClassObject) and code_object.superclass
          super(location, code_object.namespace.to_s, code_object.name.to_s, comments_from(code_object), namespace_type(code_object), code_object.visibility, superclass)
          # code_object.class_mixins.each do |m|
          #   extend_references.push Pin::Reference.new(location, path, m.path)
          # end
          # code_object.instance_mixins.each do |m|
          #   include_references.push Pin::Reference.new(location, path, m.path)
          # end
        end

        private

        def namespace_type code_object
          code_object.is_a?(YARD::CodeObjects::ClassObject) ? :class : :module
        end
      end
    end
  end
end
