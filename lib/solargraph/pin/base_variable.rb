# frozen_string_literal: true

module Solargraph
  module Pin
    class BaseVariable < Base
      # include Solargraph::Source::NodeMethods
      include Solargraph::Parser::NodeMethods

      # @return [Array<Parser::AST::Node>]
      attr_reader :assignments

      attr_accessor :mass_assignment

      # @param return_type [ComplexType, nil]
      # @param assignment [Parser::AST::Node, nil] First assignment
      #   that was made to this variable
      # @param assignments [Array<Parser::AST::Node>] Possible
      #   assignments that may have been made to this variable
      # @param mass_assignment [Array(Parser::AST::Node, Integer), nil]
      def initialize assignment: nil, assignments: [], mass_assignment: nil, return_type: nil, **splat
        super(**splat)
        @assignments = (assignment.nil? ? [] : [assignment]) + assignments
        # @type [nil, ::Array(Parser::AST::Node, Integer)]
        @mass_assignment = mass_assignment
        @return_type = return_type
      end

      def reset_generated!
        @assignment = nil
        super
      end

      def combine_with(other, attrs={})
        # @sg-ignore https://github.com/castwide/solargraph/pull/1050
        new_assignments = combine_assignments(other)
        new_attrs = attrs.merge({
          assignments: new_assignments,
          # @sg-ignore https://github.com/castwide/solargraph/pull/1050
          mass_assignment: combine_mass_assignment(other),
          return_type: combine_return_type(other),
                                })
        # @sg-ignore https://github.com/castwide/solargraph/pull/1050
        super(other, new_attrs)
      end

      # @param other [self]
      #
      # @return [Array(Parser::AST::Node, Integer), nil]
      #
      # @sg-ignore
      #   Solargraph::Pin::BaseVariable#combine_mass_assignment return
      #   type could not be inferred
      def combine_mass_assignment(other)
        assert_same(other, :mass_assignment)
      end

      # @return [Parser::AST::Node, nil]
      def assignment
        @assignment ||= assignments.last
      end

      # @param other [self]
      #
      # @return [::Array<Parser::AST::Node>]
      def combine_assignments(other)
        (other.assignments + assignments).uniq
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::VARIABLE
      end

      # @return [Integer]
      def symbol_kind
        Solargraph::LanguageServer::SymbolKinds::VARIABLE
      end

      def return_type
        @return_type ||= generate_complex_type
      end

      def nil_assignment?
        # this will always be false - should it be return_type ==
        #   ComplexType::NIL or somesuch?
        return_type.nil?
      end

      def variable?
        true
      end

      # @param parent_node [Parser::AST::Node]
      # @param api_map [ApiMap]
      # @return [::Array<ComplexType>]
      def return_types_from_node(parent_node, api_map)
        types = []
        value_position_nodes_only(parent_node).each do |node|
          # Nil nodes may not have a location
          if node.nil? || node.type == :NIL || node.type == :nil
            types.push ComplexType::NIL
          else
            rng = Range.from_node(node)
            next if rng.nil?
            pos = rng.ending
            clip = api_map.clip_at(location.filename, pos)
            # Use the return node for inference. The clip might infer from the
            # first node in a method call instead of the entire call.
            chain = Parser.chain(node, nil, nil)
            result = chain.infer(api_map, closure, clip.locals).self_to_type(closure.context)
            types.push result unless result.undefined?
          end
        end
        types
      end

      # @param api_map [ApiMap]
      # @return [ComplexType]
      def probe api_map
        assignment_types = assignments.flat_map { |node| return_types_from_node(node, api_map) }
        type_from_assignment = ComplexType.new(assignment_types.flat_map(&:items).uniq) unless assignment_types.empty?
        return type_from_assignment unless type_from_assignment.nil?

        # @todo should handle merging types from mass assignments as
        #   well so that we can do better flow sensitive typing with
        #   multiple assignments
        unless @mass_assignment.nil?
          mass_node, index = @mass_assignment
          types = return_types_from_node(mass_node, api_map)
          types.map! do |type|
            if type.tuple?
              type.all_params[index]
            elsif ['::Array', '::Set', '::Enumerable'].include?(type.rooted_name)
              type.all_params.first
            end
          end.compact!
          return ComplexType.new(types.uniq).qualify(api_map, *gates) unless types.empty?
        end

        ComplexType::UNDEFINED
      end

      # @param other [Object]
      def == other
        return false unless super
        assignment == other.assignment
      end

      def type_desc
        "#{super} = #{assignment&.type.inspect}"
      end

      private

      # See if this variable is visible within 'other_closure'
      #
      # @param other_closure [Pin::Closure]
      # @return [Boolean]
      def visible_in_closure? other_closure
        needle = closure
        haystack = other_closure

        cursor = haystack

        until cursor.nil?
          if cursor.is_a?(Pin::Method) && closure.context.tags == 'Class<>'
            # methods can't see local variables declared in their
            # parent closure
            return false
          end

          if cursor.binder.namespace == needle.binder.namespace
            return true
          end

          if cursor.return_type == needle.context
            return true
          end

          if scope == :instance && cursor.is_a?(Pin::Namespace)
            # classes and modules can't see local variables declared
            # in their parent closure, so stop here
            return false
          end

          cursor = cursor.closure
        end
        false
      end

      # @param other [self]
      # @param attr [::Symbol]
      #
      # @return [ComplexType, nil]
      def combine_types(other, attr)
        # @type [ComplexType, nil]
        type1 = send(attr)
        # @type [ComplexType, nil]
        type2 = other.send(attr)
        if type1 && type2
          types = (type1.items + type2.items).uniq
          ComplexType.new(types)
        else
          type1 || type2
        end
      end

      # @return [::Symbol]
      def scope
        :instance
      end

      # @return [ComplexType]
      def generate_complex_type
        tag = docstring.tag(:type)
        return ComplexType.try_parse(*tag.types) unless tag.nil? || tag.types.nil? || tag.types.empty?
        ComplexType.new
      end
    end
  end
end
