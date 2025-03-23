# frozen_string_literal: true

module Solargraph
  class YardMap
    class ToMethod
      module InnerMethods
        module_function

        # @param code_object [YARD::CodeObjects::Base]
        # @param location [Solargraph::Location]
        # @param comments [String]
        # @return [Array<Solargraph::Pin::Parameter>]
        def get_parameters code_object, location, comments
          return [] unless code_object.is_a?(YARD::CodeObjects::MethodObject)
          # HACK: Skip `nil` and `self` parameters that are sometimes emitted
          # for methods defined in C
          # See https://github.com/castwide/solargraph/issues/345
          code_object.parameters.select { |a| a[0] && a[0] != 'self' }.map do |a|
            Solargraph::Pin::Parameter.new(
              location: location,
              closure: self,
              comments: comments,
              name: arg_name(a),
              presence: nil,
              decl: arg_type(a),
              asgn_code: a[1]
            )
          end
        end

        # @param a [Array<String>]
        # @return [String]
        def arg_name a
          a[0].gsub(/[^a-z0-9_]/i, '')
        end

        # @param a [Array]
        # @return [::Symbol]
        def arg_type a
          if a[0].start_with?('**')
            :kwrestarg
          elsif a[0].start_with?('*')
            :restarg
          elsif a[0].start_with?('&')
            :blockarg
          elsif a[0].end_with?(':')
            a[1] ? :kwoptarg : :kwarg
          elsif a[1]
            :optarg
          else
            :arg
          end
        end
      end
      private_constant :InnerMethods

      include Helpers

      # @param code_object [YARD::CodeObjects::Base]
      # @param name [String, nil]
      # @param scope [Symbol, nil]
      # @param visibility [Symbol, nil]
      # @param closure [Solargraph::Pin::Base, nil]
      # @param spec [Solargraph::Pin::Base, nil]
      # @return [Solargraph::Pin::Method]
      def make code_object, name = nil, scope = nil, visibility = nil, closure = nil, spec = nil
        closure ||= Solargraph::Pin::Namespace.new(
          name: code_object.namespace.to_s,
          gates: [code_object.namespace.to_s]
        )
        location = object_location(code_object, spec)
        comments = code_object.docstring ? code_object.docstring.all.to_s : ''
        Pin::Method.new(
          location: location,
          closure: closure,
          name: name || code_object.name.to_s,
          comments: comments,
          scope: scope || code_object.scope,
          visibility: visibility || code_object.visibility,
          parameters: InnerMethods.get_parameters(code_object, location, comments),
          explicit: code_object.is_explicit?
        )
      end
    end
  end
end
