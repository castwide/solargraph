# frozen_string_literal: true

require 'rbs'

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

      # @return [String, nil]
      attr_reader :type_assertion

      # @param return_type [ComplexType, nil]
      # @param assignment [Parser::AST::Node, nil] First assignment
      #   that was made to this variable
      # @param assignments [Array<Parser::AST::Node>] Possible
      #   assignments that may have been made to this variable
      # @param mass_assignment [::Array(Parser::AST::Node, Integer), ::Array(Parser::AST::Node, ::Range<Integer>), nil]
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
      # @param deconstruct [Boolean] true if mass_assignment is an array
      #   pattern, which reads its subject through #deconstruct where a
      #   multiple assignment reads it through #to_ary
      # @param type_assertion [String, nil] RBS type from a trailing
      #   rbs-inline `#: TYPE` comment on the assignment
      # @param [Hash{Symbol => Object}] splat
      def initialize assignment: nil, assignments: [], mass_assignment: nil,
                     presence: nil, return_type: nil,
                     intersection_return_type: nil, exclude_return_type: nil,
                     deconstruct: false, type_assertion: nil,
                     **splat
        super(**splat)
        @type_assertion = type_assertion
        @assignments = (assignment.nil? ? [] : [assignment]) + assignments
        # @type [nil, ::Array(Parser::AST::Node, Integer), ::Array(Parser::AST::Node, ::Range<Integer>)]
        @mass_assignment = mass_assignment
        @deconstruct = deconstruct
        @return_type = return_type
        @intersection_return_type = intersection_return_type
        @exclude_return_type = exclude_return_type
        @presence = presence
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

      def combine_with other, attrs = {}
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
                                  type_assertion: choose(other, :type_assertion)
                                })
        super(other, new_attrs)
      end

      # @param other [self]
      #
      # @return [Array(AST::Node, Integer), Array(AST::Node, ::Range<Integer>), nil]
      def combine_mass_assignment other
        # @todo pick first non-nil arbitrarily - we don't yet support
        #   mass assignment merging
        mass_assignment || other.mass_assignment
      end

      # @return [Parser::AST::Node, nil]
      def assignment
        @assignment ||= assignments.last
      end

      # @param other [self]
      #
      # @return [::Array<Parser::AST::Node>]
      def combine_assignments other
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
      def return_types_from_node parent_node, api_map
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
      rescue FileNotFoundError
        # @todo Necessary for pins from source maps that are not part of the workspace
        [ComplexType::UNDEFINED]
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
          # @sg-ignore Destructuring a union of tuples types each position from its first tuple
          return adjust_type api_map, rest_capture_type(api_map, types, index) if index.is_a?(::Range)

          # Each member of a union subject, e.g. `Array<String>, Box`
          items = types.flat_map(&:items)
          if @deconstruct
            items = deconstructed_items(api_map, items)
            # A member whose elements are unknown leaves the capture unknown
            return ComplexType::UNDEFINED if items.any?(&:undefined?)
          end

          element_types = items.map do |type|
            # @sg-ignore https://github.com/apiology/solargraph/pull/406
            if type.tuple?
              # @sg-ignore https://github.com/apiology/solargraph/pull/406
              type.all_params[index]
            # @sg-ignore https://github.com/apiology/solargraph/pull/406
            elsif ['::Array', '::Set', '::Enumerable'].include?(type.rooted_name)
              # @sg-ignore https://github.com/apiology/solargraph/pull/406
              type.all_params.first
            end
          end.compact

          return ComplexType::UNDEFINED if element_types.empty?

          return adjust_type api_map, ComplexType.new(element_types.uniq).qualify(api_map, *gates)
        end

        ComplexType::UNDEFINED
      end

      # The Array bound by a `*rest` capture in an array pattern, of the
      # subject's deconstructed element types, e.g. `Array<String>` from
      # `[a, *rest]` on an `Array<String>` subject, or `Array<Integer>`
      # from `[s, *rest]` on an `Array(String, Integer)` tuple.  Plain
      # `::Array` when the element type is unknown.
      #
      # @param api_map [ApiMap]
      # @param types [::Array<ComplexType>] the subject's types
      # @param range [::Range<Integer>] subject positions the rest covers
      # @return [ComplexType]
      def rest_capture_type api_map, types, range
        items = deconstructed_items(api_map, types.flat_map(&:items))
        return ComplexType.parse('::Array') if items.any?(&:undefined?)

        elements = items.flat_map do |type|
          next type.all_params[range] || [] if type.tuple?
          next [] unless type.rooted_name == '::Array'

          type.all_params
        end
        return ComplexType.parse('::Array') if elements.empty?

        element_type = ComplexType.new(elements.flat_map(&:items).uniq)
        array_type = ComplexType::UniqueType.new('Array', [], [element_type], rooted: true, parameters_type: :list)
        ComplexType.new([array_type]).qualify(api_map, *gates)
      end

      NEVER_DECONSTRUCTED = %w[::Integer ::Float ::Symbol ::TrueClass ::FalseClass ::Boolean].freeze
      private_constant :NEVER_DECONSTRUCTED

      # What an array pattern matches against, for each member of a
      # subject: the member itself if it is already an Array, else the
      # return type of its `deconstruct` method.
      #
      # @param api_map [ApiMap]
      # @param items [::Array<ComplexType::UniqueType>]
      # @return [::Array<ComplexType::UniqueType>]
      def deconstructed_items api_map, items
        items.flat_map do |type|
          next [type] if type.rooted_name == '::Array'

          # These never match an array pattern, and no subclass can add #deconstruct
          next [] if type.nil_type? || NEVER_DECONSTRUCTED.include?(type.rooted_name)

          deconstruct = api_map.get_method_stack(type.rooted_tag, 'deconstruct').first
          # A subclass or a type we cannot see into may still deconstruct
          next [ComplexType::UniqueType::UNDEFINED] if deconstruct.nil?

          deconstruct.typify(api_map).self_to_type(type).items
        end
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
        # A narrowing to a value constant (`in PATTERN => f`) is no declared type
        return ComplexType::UNDEFINED if @return_type.nil? && narrowed_to_value_constant?(api_map)

        raw_return_type = super

        adjust_type(api_map, raw_return_type)
      end

      # @sg-ignore need boolish support for ? methods
      def presence_certain?
        exclude_return_type || intersection_return_type
      end

      # @param other_loc [Location]
      # @sg-ignore flow sensitive typing needs to handle attrs
      def starts_at? other_loc
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
      def combine_presence other
        return presence || other.presence if presence.nil? || other.presence.nil?

        # @sg-ignore flow sensitive typing needs to handle attrs
        Range.new([presence.start, other.presence.start].max, [presence.ending, other.presence.ending].min)
      end

      # @param other [self]
      # @return [Pin::Closure, nil]
      def combine_closure other
        return closure if closure == other.closure

        # choose first defined, as that establishes the scope of the variable
        if closure.nil? || other.closure.nil?
          Solargraph.assert_or_log(:varible_closure_missing) do
            'One of the local variables being combined is missing a closure: ' \
              "#{inspect} vs #{other.inspect}"
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
      def visible_at? other_closure, other_loc
        # @sg-ignore flow sensitive typing needs to handle attrs
        location.filename == other_loc.filename &&
          # @sg-ignore flow sensitive typing needs to handle attrs
          (!presence || presence.include?(other_loc.range.start)) &&
          visible_in_closure?(other_closure)
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
      def adjust_type api_map, raw_return_type
        qualified_exclude = exclude_return_type&.qualify(api_map, *(closure&.gates || ['']))
        minus_exclusions = raw_return_type.exclude qualified_exclude, api_map
        intersection = narrowed_to_value_constant?(api_map) ? nil : intersection_return_type
        qualified_intersection = intersection&.qualify(api_map, *(closure&.gates || ['']))
        minus_exclusions.intersect_with qualified_intersection, api_map
      end

      # True if narrowed to a constant that is not a class or module,
      # e.g. `in PATTERN` with `PATTERN = /abc/`: a pattern matches it
      # with ===, which says nothing about the type
      #
      # @param api_map [ApiMap]
      # @return [Boolean]
      def narrowed_to_value_constant? api_map
        intersection = intersection_return_type
        return false if intersection.nil?

        gates = closure&.gates || ['']
        intersection.items.any? do |unique_type|
          # Resolved as a constant reference is, through superclasses and mixins
          path = api_map.resolve(unique_type.name, gates)
          !path.nil? && api_map.get_path_pins(path).any?(Pin::Constant)
        end
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
      def combine_return_type other
        combine_types(other, :return_type)
      end

      # @param other [self]
      # @param attr [::Symbol]
      #
      # @return [ComplexType, nil]
      def combine_types other, attr
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

      # An rbs-inline type assertion takes precedence over a @type tag,
      # as inline RBS method signatures do over YARD tags.
      #
      # @return [ComplexType, nil]
      def generate_complex_type
        asserted = type_from_assertion
        return asserted unless asserted.nil?
        tag = docstring.tag(:type)
        return ComplexType.try_parse(*tag.types) unless tag.nil? || tag.types.nil? || tag.types.empty?
        nil
      end

      # @return [ComplexType, nil]
      def type_from_assertion
        assertion = type_assertion
        return nil if assertion.nil? || assertion.empty?
        @type_from_assertion ||= begin
          rbs_type = RBS::Parser.parse_type(assertion, require_eof: true)
          RbsTranslator.to_complex_type(rbs_type) unless rbs_type.nil?
        rescue RBS::ParsingError
          nil
        end
      end
    end
  end
end
