# frozen_string_literal: true

module Solargraph
  module Pin
    module YardPin
      class Method < Pin::Method
        include YardMixin

        def initialize code_object, name = nil, scope = nil, visibility = nil, closure = nil, spec = nil
          closure ||= Solargraph::Pin::Namespace.new(
            name: code_object.namespace.to_s,
            gates: [code_object.namespace.to_s]
          )
          super(
            location: object_location(code_object, spec),
            closure: closure,
            name: name || code_object.name.to_s,
            comments: code_object.docstring ? code_object.docstring.all.to_s : '',
            scope: scope || code_object.scope,
            visibility: visibility || code_object.visibility,
            args: get_parameters(code_object)
          )
        end

        private

        def get_parameters code_object
          return [] unless code_object.is_a?(YARD::CodeObjects::MethodObject)
          args = []
          code_object.parameters.each do |a|
            p = a[0]
            unless a[1].nil?
              p += ' =' unless p.end_with?(':')
              p += " #{a[1]}"
            end
            args.push p
          end
          args
        end
      end
    end
  end
end
