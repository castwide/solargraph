# frozen_string_literal: true

module Solargraph
  module Pin
    class BaseVariable < Base
      # include Solargraph::Source::NodeMethods
      include Solargraph::Parser::NodeMethods

      # @return [Parser::AST::Node, nil]
      attr_reader :assignment

      attr_accessor :mass_assignment

      # @param return_type [ComplexType, nil]
      # @param mass_assignment [::Array(Parser::AST::Node, Integer), nil]
      # @param assignment [Parser::AST::Node, nil]
      # @param exclude_return_type [ComplexType, nil] Ensure any
      #   return type returned will never include any of these unique
      #   types in the unique types of its complex type.
      #
      #   Example: If a return type is 'Float | Integer | nil' and the
      #   exclude_return_type is 'Integer', the resulting return
      #   type will be 'Float | nil' because Integer is excluded.
      # @param intersection_return_type [ComplexType, nil] Ensure each unique
      #   return type is compatible with at least one element of this
      #   complex type.  If a ComplexType used as a return type is an
      #   union type - we can return any of these - these are
      #   intersection types - everything we return needs to meet at least
      #   one of these unique types.
      #
      #   Example: If a return type is 'Numeric | nil' and the
      #   intersection_return_type is 'Float | nil', the resulting return
      #   type will be 'Float | nil' because Float is compatible
      #   with Numeric and nil is compatible with nil.
      # @see https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#union-types
      # @see https://en.wikipedia.org/wiki/Intersection_type#TypeScript_example
      # @param mass_assignment [Array(Parser::AST::Node, Integer), nil]
      def initialize assignment: nil, mass_assignment: nil, return_type: nil,
                     intersection_return_type: nil, exclude_return_type: nil,
                     **splat
        super(**splat)
        @assignment = assignment
        # @type [nil, ::Array(Parser::AST::Node, Integer)]
        @mass_assignment = nil
        @return_type = return_type
        @intersection_return_type = intersection_return_type
        @exclude_return_type = exclude_return_type
      end

      # @param presence [Range]
      # @param exclude_return_type [ComplexType, nil]
      # @param intersection_return_type [ComplexType, nil]
      # @param source [::Symbol]
      #
      # @return [self]
      def downcast presence:, exclude_return_type: nil, intersection_return_type: nil,
                   source: self.source
        result = dup
        result.exclude_return_type = exclude_return_type
        result.intersection_return_type = intersection_return_type
        result.source = source
        result.presence = presence
        result.reset_generated!
        result
      end

      def combine_with(other, attrs={})
        new_attrs = attrs.merge({
          assignment: assert_same(other, :assignment),
          mass_assignment: assert_same(other, :mass_assignment),
          return_type: combine_return_type(other),
          # @sg-ignore https://github.com/castwide/solargraph/pull/1050
          intersection_return_type: combine_types(other, :intersection_return_type),
          # @sg-ignore https://github.com/castwide/solargraph/pull/1050
          exclude_return_type: combine_types(other, :exclude_return_type),
        })
        # @sg-ignore https://github.com/castwide/solargraph/pull/1050
        super(other, new_attrs)
      end

      def reset_generated!
        @return_type_minus_exclusions = nil
        super
      end

      def inner_desc
        super + ", intersection_return_type=#{intersection_return_type&.rooted_tags.inspect}, exclude_return_type=#{exclude_return_type&.rooted_tags.inspect}"
      end

      # @param other [self]
      #
      # @return [Array(AST::Node, Integer), nil]
      def combine_mass_assignment(other)
        # @todo pick first non-nil arbitrarily - we don't yet support
        #   mass assignment merging
        mass_assignment || other.mass_assignment
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::VARIABLE
      end

      # @return [Integer]
      def symbol_kind
        Solargraph::LanguageServer::SymbolKinds::VARIABLE
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
      # @return [ComplexType, ComplexType::UniqueType]
      def probe api_map
        unless @assignment.nil?
          types = return_types_from_node(@assignment, api_map)
          return adjust_type api_map, ComplexType.new(types.uniq) unless types.empty?
        end

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

          return ComplexType::UNDEFINED if types.empty?

          return adjust_type api_map, ComplexType.new(types.uniq).qualify(api_map, *gates)
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

      # @return [ComplexType, nil]
      def return_type
        generate_complex_type || @return_type || intersection_return_type || ComplexType::UNDEFINED
      end

      def typify api_map
        raw_return_type = super

        adjust_type(api_map, raw_return_type)
      end

      # @sg-ignore need boolish support for ? methods
      def presence_certain?
        exclude_return_type || intersection_return_type
      end

      protected

      attr_accessor :exclude_return_type, :intersection_return_type

      # @return [Range]
      attr_writer :presence

      private

      # @param api_map [ApiMap]
      # @param raw_return_type [ComplexType, ComplexType::UniqueType]
      #
      # @return [ComplexType, ComplexType::UniqueType]
      def adjust_type(api_map, raw_return_type)
        qualified_exclude = exclude_return_type&.qualify(api_map, *(closure&.gates || ['']))
        minus_exclusions = raw_return_type.exclude qualified_exclude, api_map
        qualified_intersection = intersection_return_type&.qualify(api_map, *(closure&.gates || ['']))
        minus_exclusions.intersect_with qualified_intersection, api_map
      end

      # @param other [self]
      # @return [Pin::Closure, nil]
      def combine_closure(other)
        return closure if self.closure == other.closure

        # choose first defined, as that establishes the scope of the variable
        if closure.nil? || other.closure.nil?
          Solargraph.assert_or_log(:varible_closure_missing) do
            "One of the local variables being combined is missing a closure: " \
              "#{self.inspect} vs #{other.inspect}"
          end
          return closure || other.closure
        end

        if closure.location.nil? || other.closure.location.nil?
          return closure.location.nil? ? other.closure : closure
        end

        # if filenames are different, this will just pick one
        # @sg-ignore flow sensitive typing needs to handle ivars
        return closure if closure.location <= other.closure.location

        other.closure
      end

      # See if this variable is visible within 'other_closure'
      #
      # @param other_closure [Pin::Closure]
      # @return [Boolean]
      def visible_in_closure? other_closure
        needle = closure
        return false if closure.nil?
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
      # @return [ComplexType, nil]
      def combine_return_type(other)
        combine_types(other, :return_type)
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

      # @return [ComplexType, nil]
      def generate_complex_type
        tag = docstring.tag(:type)
        return ComplexType.try_parse(*tag.types) unless tag.nil? || tag.types.nil? || tag.types.empty?
        nil
      end
    end
  end
end
