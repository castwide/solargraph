# frozen_string_literal: true

module Solargraph
  class TypeChecker
    # Definitions of type checking rules to be performed at various levels
    #
    class Rules
      LEVELS = {
        normal: 0,
        typed: 1,
        strict: 2,
        strong: 3,
        alpha: 4
      }.freeze

      # @return [Symbol]
      attr_reader :level

      # @return [Integer]
      attr_reader :rank

      # @param level [Symbol]
      def initialize level
        @rank = if LEVELS.key?(level)
          LEVELS[level]
        else
          Solargraph.logger.warn "Unrecognized TypeChecker level #{level}, assuming normal"
          0
        end
        @level = LEVELS[LEVELS.values.index(@rank)]
      end

      def ignore_all_undefined?
        rank < LEVELS[:strict]
      end

      def validate_consts?
        rank >= LEVELS[:strict]
      end

      def validate_calls?
        rank >= LEVELS[:strict]
      end

      def require_type_tags?
        rank >= LEVELS[:strong]
      end

      def must_tag_or_infer?
        rank > LEVELS[:typed]
      end

      def validate_tags?
        rank > LEVELS[:normal]
      end

      def require_inferred_type_params?
        rank >= LEVELS[:alpha]
      end

      # @todo 64: Need to add nil check here
      # @todo 43: flow sensitive typing needs to handle && with variables
      # @todo 25: flow sensitive typing needs to handle "return if foo.nil?"
      # @todo 12: need to be able to resolve same method signature on two different types
      # @todo 11: flow sensitive typing needs to handle "unless foo.nil?"
      # @todo 9: Need to validate config
      # @todo 8: Should better support meaning of '&' in RBS
      # @todo 7: literal arrays in this module turn into ::Solargraph::Source::Chain::Array
      # @todo 6: flow sensitive typing needs to handle "else"
      # @todo 5: flow sensitive typing needs to handle ternary operator
      # @todo 5: flow sensitive typing needs to handle inner closures
      # @todo 5: flow sensitive typing needs better handling of ||= on ivars
      # @todo 4: need boolish support for ? methods
      # @todo 4: should understand meaning of &.
      # @todo 4: Need support for reduce_class_type in UniqueType
      # @todo 4: flow sensitive typing needs to handle 'return if'
      # @todo 3: Need to handle implicit nil on else
      # @todo 2: flow sensitive typing needs better handling of ||= on lvars
      # @todo 2: Should handle redefinition of types in simple contexts
      # @todo 2: Translate to something flow sensitive typing understands
      # @todo 2: flow sensitive typing needs to handle if on ivars
      # @todo 2: flow sensitive typing needs to handle "while foo""
      # @todo 1: flow sensitive typing needs to handle 'raise if'
      # @todo 1: To make JSON strongly typed we'll need a record syntax
      # @todo 1: Untyped method Solargraph::Pin::Base#assert_same could not be inferred
      # @todo 1: foo = 1; foo = 2 if bar? should be of type 'Integer', not 'Integer, nil'
      # @todo 1: flow sensitive typing needs to handle "if !foo"
      def require_all_unique_types_match_expected?
        rank >= LEVELS[:strong]
      end

      def require_all_unique_types_match_expected_on_lhs?
        rank >= LEVELS[:strong]
      end

      def require_no_undefined_args?
        rank >= LEVELS[:alpha]
      end

      def require_generics_resolved?
        rank >= LEVELS[:alpha]
      end

      def require_interfaces_resolved?
        rank >= LEVELS[:alpha]
      end

      def require_downcasts?
        rank >= LEVELS[:alpha]
      end

      # We keep this at strong because if you added an @ sg-ignore to
      # address a strong-level issue, then ran at a lower level, you'd
      # get a false positive - we don't run stronger level checks than
      # requested for performance reasons
      def validate_sg_ignores?
        rank >= LEVELS[:strong]
      end
    end
  end
end
