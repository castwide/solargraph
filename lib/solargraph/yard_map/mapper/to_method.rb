# frozen_string_literal: true

module Solargraph
  class YardMap
    class Mapper
      module ToMethod
        extend YardMap::Helpers

        VISIBILITY_OVERRIDE = {
          # YARD pays attention to 'private' statements prior to class methods but shouldn't
          ["Rails::Engine", :class, "find_root_with_flag"] => :public
        }

        # @param code_object [YARD::CodeObjects::Base]
        # @param name [String, nil]
        # @param scope [Symbol, nil]
        # @param visibility [Symbol, nil]
        # @param closure [Solargraph::Pin::Namespace, nil]
        # @param spec [Gem::Specification, nil]
        # @return [Solargraph::Pin::Method]
        def self.make code_object, name = nil, scope = nil, visibility = nil, closure = nil, spec = nil
          closure ||= create_closure_namespace_for(code_object, spec)
          location = object_location(code_object, spec)
          name ||= code_object.name.to_s
          return_type = ComplexType::SELF if name == 'new'
          comments = code_object.docstring ? code_object.docstring.all.to_s : ''
          final_scope = scope || code_object.scope
          override_key = [closure.path, final_scope, name]
          final_visibility = VISIBILITY_OVERRIDE[override_key]
          final_visibility ||= VISIBILITY_OVERRIDE[override_key[0..-2]]
          final_visibility ||= :private if closure.path == 'Kernel' && Kernel.private_instance_methods(false).include?(name)
          final_visibility ||= visibility
          final_visibility ||= :private if code_object.module_function? && final_scope == :instance
          final_visibility ||= :public if code_object.module_function? && final_scope == :class
          final_visibility ||= code_object.visibility
          if code_object.is_alias?
            origin_code_object = code_object.namespace.aliases[code_object]
            pin = Pin::MethodAlias.new(
              name: name,
              location: location,
              original: origin_code_object.name.to_s,
              closure: closure,
              comments: comments,
              scope: final_scope,
              visibility: final_visibility,
              explicit: code_object.is_explicit?,
              return_type: return_type,
              parameters: [],
              source: :yardoc,
            )
          else
            pin = Pin::Method.new(
              location: location,
              closure: closure,
              name: name,
              comments: comments,
              scope: final_scope,
              visibility: final_visibility,
              # @todo Might need to convert overloads to signatures
              explicit: code_object.is_explicit?,
              return_type: return_type,
              attribute: code_object.is_attribute?,
              parameters: [],
              source: :yardoc,
            )
            pin.parameters.concat get_parameters(code_object, location, comments, pin)
            pin.parameters.freeze
          end
          logger.debug { "ToMethod.make: Just created method pin: #{pin.inspect}" }
          pin
        end

        class << self
          include Logging

          private

          # @param code_object [YARD::CodeObjects::Base]
          # @param location [Location],
          # @param comments [String]
          # @param pin [Pin::Base]
          # @return [Array<Solargraph::Pin::Parameter>]
          def get_parameters code_object, location, comments, pin
            return [] unless code_object.is_a?(YARD::CodeObjects::MethodObject)
            # HACK: Skip `nil` and `self` parameters that are sometimes emitted
            # for methods defined in C
            # See https://github.com/castwide/solargraph/issues/345
            code_object.parameters.select { |a| a[0] && a[0] != 'self' }.map do |a|
              Solargraph::Pin::Parameter.new(
                location: location,
                closure: pin,
                comments: comments,
                name: arg_name(a),
                presence: nil,
                decl: arg_type(a),
                asgn_code: a[1],
                source: :yardoc,
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
      end
    end
  end
end
