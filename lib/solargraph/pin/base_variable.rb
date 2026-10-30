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

      # @return [Boolean]
      attr_accessor :definite

      # Self, or a definite copy of it when the assignment dominates
      # `location` - see #definitely_visible_at?.
      #
      # @param location [Location, nil]
      # @return [self]
      def definite_at location
        return self if definite || !definitely_visible_at?(location)

        result = dup
        result.definite = true
        result
      end

      # The CompoundStatement this assignment was made within. Used by
      # #definitely_visible_at? to decide whether it dominates a reference.
      #
      # @return [Pin::CompoundStatement, nil]
      attr_reader :compound_statement

      # @return [String, nil]
      attr_reader :type_assertion

      # True for a copy of a branch's assignment carried past the
      # branch, to where its paths rejoin - see #rejoin
      #
      # @return [Boolean]
      attr_reader :rejoined

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
      # @param definite [Boolean] True if the assignment is guaranteed to
      #   have run by its presence start, so its type may override rather
      #   than union with earlier ones.
      # @param compound_statement [Pin::CompoundStatement, nil] Where the
      #   assignment was made; lets a non-definite one still override
      #   within its own range - see #definitely_visible_at?.
      # @param type_assertion [String, nil] RBS type from a trailing
      #   rbs-inline `#: TYPE` comment on the assignment
      # @param [Hash{Symbol => Object}] splat
      def initialize assignment: nil, assignments: [], mass_assignment: nil,
                     presence: nil, return_type: nil,
                     intersection_return_type: nil, exclude_return_type: nil,
                     definite: true,
                     compound_statement: nil,
                     type_assertion: nil,
                     **splat
        super(**splat)
        @type_assertion = type_assertion
        @assignments = (assignment.nil? ? [] : [assignment]) + assignments
        # @type [nil, ::Array(Parser::AST::Node, Integer)]
        @mass_assignment = mass_assignment
        @return_type = return_type
        @intersection_return_type = intersection_return_type
        @exclude_return_type = exclude_return_type
        @presence = presence
        @definite = definite
        @compound_statement = compound_statement
        @rejoined = false
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

      # A copy of this assignment for `presence`, past the end of the
      # branch it was made in, that adds to rather than overrides what
      # the other paths into `presence` assigned: ApiMap
      # #var_pins_at_location types it apart from them.
      #
      # @param presence [Range]
      # @return [self]
      def rejoin presence
        result = dup
        result.presence = presence
        result.definite = false
        result.rejoined = true
        result
      end

      # True if `other` overwrites our value with a different
      # assignment, rather than narrowing the same one
      #
      # @param other [self]
      # @return [Boolean]
      def overwritten_by? other
        override_assignments?(other) && !same_assignment_sites?(other)
      end

      # @param presence [Range]
      #
      # @return [self]
      def with_presence presence
        result = dup
        result.presence = presence
        result
      end

      def reset_generated!
        @assignment = nil
        super
      end

      # @param other [self]
      # @param attrs [Hash]
      def combine_with other, attrs = {}
        superseded = override_assignments?(other)
        # a reassignment replaces the declared type too; parameters
        # combined from several signatures don't reassign each other
        redeclared = superseded && !other.is_a?(Parameter)
        # Facts expire only when a *different* assignment overwrote the
        # value they describe.  Two flow-sensitive downcasts of the same
        # assignment - e.g. the one per operand that `a.nil? ||
        # a.empty? || a == 'x'` produces - are additional facts about
        # one value, and must accumulate rather than replace each other.
        facts_superseded = superseded && !same_assignment_sites?(other)
        new_assignments = combine_assignments(other)
        new_attrs = attrs.merge({
                                  # default values don't exist in RBS parameters; it just
                                  # tells you if the arg is optional or not.  Prefer a
                                  # provided value if we have one here since we can't rely on
                                  # it from RBS so we can infer from it and typecheck on it.
                                  #
                                  # Skipped when #combine_assignments supersedes: the
                                  # constructor would re-add the dropped node.
                                  assignment: superseded ? nil : choose(other, :assignment),
                                  assignments: new_assignments,
                                  mass_assignment: combine_mass_assignment(other),
                                  # a superseding assignment also replaces the old
                                  # value's declared type, e.g. an earlier @type tag
                                  return_type: redeclared ? defined_or_nil(other.return_type) : combine_return_type(other),
                                  # Narrowing recorded against the old value expires
                                  # when that value is definitely overwritten, so when
                                  # `other`'s assignment supersedes ours, keep only the
                                  # facts asserted about the new value.
                                  intersection_return_type: if facts_superseded
                                                              other.intersection_return_type
                                                            else
                                                              combine_types(other, :intersection_return_type)
                                                            end,
                                  exclude_return_type: if facts_superseded
                                                         other.exclude_return_type
                                                       else
                                                         combine_types(other, :exclude_return_type)
                                                       end,
                                  presence: combine_presence(other),
                                  # a guaranteed assignment on either side may
                                  # override, not just union with, the rest
                                  definite: definite || other.definite || superseded,
                                  # like the @type tag, a superseding assignment's
                                  # #: assertion replaces the old one
                                  type_assertion: redeclared ? other.type_assertion : choose(other, :type_assertion)
                                })
        new_attrs.merge!(comments: other.comments, docstring: other.docstring) if redeclared
        super(other, new_attrs)
      end

      # @param other [self]
      #
      # @return [Array(AST::Node, Integer), nil]
      def combine_mass_assignment other
        # @todo pick first non-nil arbitrarily - we don't yet support
        #   mass assignment merging
        mass_assignment || other.mass_assignment
      end

      # True when `other`'s assignments are the very same ones as ours,
      # identified by source position.  Structural node equality is not
      # usable here - two textually identical assignments on different
      # lines compare equal, and telling those apart is the whole point.
      #
      # @param other [self]
      # @return [Boolean]
      def same_assignment_sites? other
        assignment_sites == other.assignment_sites
      end

      # Inference skips a pin whose identity is already being probed, and
      # a combined pin keeps its first part's location, so the assignment
      # sites are what tell `x = 1; x = x.to_s` apart from the `x = 1`
      # that its value reads.
      #
      # @return [String]
      def identity
        "#{super}|#{assignment_sites.map(&:inspect).join(',')}"
      end

      # @return [::Array<Solargraph::Range, nil>]
      def assignment_sites
        assignments.map { |node| Solargraph::Range.from_node(node) }
      end

      # @return [Parser::AST::Node, nil]
      def assignment
        @assignment ||= assignments.last
      end

      # @param type [ComplexType, nil]
      # @return [ComplexType, nil]
      def defined_or_nil type
        return nil if type.nil? || type.undefined?

        type
      end

      # @param other [self]
      # @return [::Array<Parser::AST::Node>]
      def combine_assignments other
        return other.assignments.dup if override_assignments?(other)

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
          !within_own_assignment?(other_loc) &&
          visible_in_closure?(other_closure)
      end

      protected

      attr_accessor :exclude_return_type, :intersection_return_type

      # @return [Range]
      attr_writer :presence

      # @return [Boolean]
      attr_writer :rejoined

      public

      # The values assigned to us, including the right-hand side of a
      # multiple assignment like `a, b = pair`
      #
      # @return [::Array<Parser::AST::Node>]
      def value_nodes
        mass_node = mass_assignment&.first
        mass_node ? assignments + [mass_node] : assignments
      end

      # True if `other_loc` sits inside one of our own assignment value
      # nodes - the receiver `x` in `x = x.length`. Such a reference must
      # resolve against our other assignments, not the value being derived.
      #
      # @param other_loc [Location]
      # @return [Boolean]
      def within_own_assignment? other_loc
        return false unless location&.filename == other_loc.filename

        value_nodes.any? do |assignment_node|
          next false unless assignment_node.respond_to?(:loc)

          rng = Range.from_node(assignment_node)
          next false if rng.nil?

          # The new value is visible from the node end onward, so exclude
          # only positions strictly inside it.
          rng.contain?(other_loc.range.start) && other_loc.range.start != rng.ending
        end
      end

      private

      # True if `other` supersedes us rather than unioning: it reassigns
      # the same variable in the same scope, guaranteed to have run.  A
      # self-referencing reassignment (`x = x.foo`) supersedes too: its
      # value still reads the earlier binding, per #within_own_assignment?
      #
      # @param other [self]
      # @return [Boolean]
      def override_assignments? other
        other.definite && within_closure?(other.closure)
      end

      # True if `other_closure` is our closure or a block nested in it,
      # where an assignment reassigns this same variable
      #
      # @param other_closure [Pin::Closure, nil]
      # @return [Boolean]
      def within_closure? other_closure
        candidate = other_closure
        while candidate
          return true if candidate == closure
          return false unless candidate.is_a?(Pin::Block)

          candidate = candidate.closure
        end
        false
      end

      public

      # True if this assignment, though not globally definite, still
      # dominates `location`: `location` falls inside the branch body it
      # was made in. Nesting needs no walk - inner ranges are subranges.
      #
      # @param location [Location, nil]
      # @return [Boolean]
      def definitely_visible_at? location
        cs = compound_statement
        return false unless location && cs&.location&.range

        # @sg-ignore flow sensitive typing needs to handle attrs
        cs.location.filename == location.filename &&
          # @sg-ignore flow sensitive typing needs to handle attrs
          cs.location.range.contain?(location.range.start)
      end

      private

      # @param node [Parser::AST::Node, nil]
      # @return [Boolean]
      def references_name? node
        return false unless node.is_a?(::AST::Node)

        # @sg-ignore flow sensitive typing doesn't narrow `node` past the guard above
        return true if %i[lvar ivar].include?(node.type) && node.children[0].to_s == name

        # @sg-ignore flow sensitive typing doesn't narrow `node` past the guard above
        node.children.any? { |child| references_name?(child) }
      end

      # @param api_map [ApiMap]
      # @param raw_return_type [ComplexType, ComplexType::UniqueType]
      #
      # @return [ComplexType, ComplexType::UniqueType]
      def adjust_type api_map, raw_return_type
        qualified_exclude = exclude_return_type&.qualify(api_map, *(closure&.gates || ['']))
        minus_exclusions = raw_return_type.exclude qualified_exclude, api_map
        qualified_intersection = intersection_return_type&.qualify(api_map, *(closure&.gates || ['']))
        minus_exclusions.intersect_with qualified_intersection, api_map
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
