# frozen_string_literal: true

module Solargraph
  module Pin
    module YardPin
      class Method < Pin::Method
        include YardMixin

        def initialize code_object, name = nil, scope = nil, visibility = nil, closure = nil, spec = nil
          # @code_object = code_object
          # @spec = spec
          @location = object_location(code_object, spec)
          @parameters = get_parameters(code_object)
          @comments ||= code_object.docstring ? code_object.docstring.all.to_s : ''
          closure ||= Solargraph::Pin::Namespace.new(
            name: code_object.namespace.to_s,
            gates: [code_object.namespace.to_s]
          )
          super(
            location: location,
            closure: closure,
            name: name || code_object.name.to_s,
            comments: nil,
            scope: scope || code_object.scope,
            visibility: visibility || code_object.visibility,
            args: nil
          )
        end

        # def parameters
        #   @parameters ||= get_parameters(code_object)
        # end

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
