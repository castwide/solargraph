# frozen_string_literal: true

module Solargraph
  module Pin
    class BaseVariable < Base
      # include Solargraph::Source::NodeMethods
      include Solargraph::Parser::NodeMethods

      # @return [Array<Parser::AST::Node>]
      attr_reader :assignments

      attr_accessor :mass_assignment

      # @return [Range, nil]
      attr_reader :presence

      # @param return_type [ComplexType, nil]
      # @param assignment [Parser::AST::Node, nil] First assignment
      #   that was made to this variable
      # @param assignments [Array<Parser::AST::Node>] Possible
      #   assignments that may have been made to this variable
      # @param mass_assignment [::Array(Parser::AST::Node, Integer), nil]
      # @param assignment [Parser::AST::Node, nil] First assignment
      #   that was made to this variable
      # @param assignments [Array<Parser::AST::Node>] Possible
      #   assignments that may have been made to this variable
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
      # @param presence [Range, nil]
      # @param presence_certain [Boolean]
      def initialize assignment: nil, assignments: [], mass_assignment: nil,
                     presence: nil, presence_certain: false, return_type: nil,
                     intersection_return_type: nil, exclude_return_type: nil,
                     **splat
        super(**splat)
        @assignments = (assignment.nil? ? [] : [assignment]) + assignments
        # @type [nil, ::Array(Parser::AST::Node, Integer)]
        @mass_assignment = mass_assignment
        @return_type = return_type
        @intersection_return_type = intersection_return_type
        @exclude_return_type = exclude_return_type
        @presence = presence
        @presence_certain = presence_certain
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

      def reset_generated!
        @assignment = nil
        super
      end

      def combine_with(other, attrs={})
        new_assignments = combine_assignments(other)
        new_attrs = attrs.merge({
          # default values don't exist in RBS parameters; it just
          # tells you if the arg is optional or not.  Prefer a
          # provided value if we have one here since we can't rely on
          # it from RBS so we can infer from it and typecheck on it.
          assignment: choose(other, :assignment),
          assignments: new_assignments,
          mass_assignment: combine_mass_assignment(other),
          return_type: combine_return_type(other),
          intersection_return_type: combine_types(other, :intersection_return_type),
          exclude_return_type: combine_types(other, :exclude_return_type),
          presence: combine_presence(other),
          presence_certain: combine_presence_certain(other)
        })
        super(other, new_attrs)
      end

      # @param other [self]
      #
      # @return [Array(AST::Node, Integer), nil]
      def combine_mass_assignment(other)
        # @todo pick first non-nil arbitrarily - we don't yet support
        #   mass assignment merging
        mass_assignment || other.mass_assignment
      end

      # If a certain pin is being combined with an uncertain pin, we
      # end up with a certain result
      #
      # @param other [self]
      #
      # @return [Boolean]
      def combine_presence_certain(other)
        presence_certain? || other.presence_certain?
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

      def inner_desc
        super + ", presence=#{presence.inspect}, assignments=#{assignments}, " \
                "intersection_return_type=#{intersection_return_type&.rooted_tags.inspect}, " \
                "exclude_return_type=#{exclude_return_type&.rooted_tags.inspect}"
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
            # @sg-ignore Need to add nil check here
            clip = api_map.clip_at(location.filename, pos)
            # Use the return node for inference. The clip might infer from the
            # first node in a method call instead of the entire call.
            chain = Parser.chain(node, nil, nil)
            # @sg-ignore Need to add nil check here
            result = chain.infer(api_map, closure, clip.locals).self_to_type(closure.context)
            types.push result unless result.undefined?
          end
        end
        types
      end

      # @param api_map [ApiMap]
      # @return [ComplexType, ComplexType::UniqueType]
      def probe api_map
        assignment_types = assignments.flat_map { |node| return_types_from_node(node, api_map) }
        type_from_assignment = ComplexType.new(assignment_types.flat_map(&:items).uniq) unless assignment_types.empty?
        return adjust_type api_map, type_from_assignment unless type_from_assignment.nil?

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
        # @sg-ignore Should add type check on other
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

      # @param other_loc [Location]
      # @sg-ignore flow sensitive typing needs to handle attrs
      def starts_at?(other_loc)
        location&.filename == other_loc.filename &&
          presence &&
          # @sg-ignore flow sensitive typing needs to handle attrs
          presence.start == other_loc.range.start
      end

      # Narrow the presence range to the intersection of both.
      #
      # @param other [self]
      #
      # @return [Range, nil]
      def combine_presence(other)
        return presence || other.presence if presence.nil? || other.presence.nil?

        # @sg-ignore flow sensitive typing needs to handle attrs
        Range.new([presence.start, other.presence.start].max, [presence.ending, other.presence.ending].min)
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

        # @sg-ignore flow sensitive typing needs to handle attrs
        if closure.location.nil? || other.closure.location.nil?
          # @sg-ignore flow sensitive typing needs to handle attrs
          return closure.location.nil? ? other.closure : closure
        end

        # if filenames are different, this will just pick one
        # @sg-ignore flow sensitive typing needs to handle attrs
        return closure if closure.location <= other.closure.location

        other.closure
      end

      # @param other_closure [Pin::Closure]
      # @param other_loc [Location]
      def visible_at?(other_closure, other_loc)
        # @sg-ignore flow sensitive typing needs to handle attrs
        location.filename == other_loc.filename &&
          # @sg-ignore flow sensitive typing needs to handle attrs
          (!presence || presence.include?(other_loc.range.start)) &&
          visible_in_closure?(other_closure)
      end

      def presence_certain?
        @presence_certain
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

        # @sg-ignore Need to add nil check here
        if closure.location.nil? || other.closure.location.nil?
          # @sg-ignore Need to add nil check here
          return closure.location.nil? ? other.closure : closure
        end

        # if filenames are different, this will just pick one
        # @sg-ignore flow sensitive typing needs to handle attrs
        return closure if closure.location <= other.closure.location

        other.closure
      end

      # See if this variable is visible within 'viewing_closure'
      #
      # @param viewing_closure [Pin::Closure]
      # @return [Boolean]
      def visible_in_closure? viewing_closure
        return false if closure.nil?

        # if we're declared at top level, we can't be seen from within
        # methods declared tere

        # @sg-ignore Need to add nil check here
        return false if viewing_closure.is_a?(Pin::Method) && closure.context.tags == 'Class<>'

        # @sg-ignore Need to add nil check here
        return true if viewing_closure.binder.namespace == closure.binder.namespace

        # @sg-ignore Need to add nil check here
        return true if viewing_closure.return_type == closure.context

        # classes and modules can't see local variables declared
        # in their parent closure, so stop here
        return false if scope == :instance && viewing_closure.is_a?(Pin::Namespace)

        parent_of_viewing_closure = viewing_closure.closure

        return false if parent_of_viewing_closure.nil?

        visible_in_closure?(parent_of_viewing_closure)
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
