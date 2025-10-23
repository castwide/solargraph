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

      # pending code fixes (~280):
      #
      # @todo 266: Need to add nil check here
      # @todo 9: Need to validate config
      # @todo 3: Translate to something flow sensitive typing understands
      # @todo 2: Need a downcast here
      #
      # flow-sensitive typing could handle (~100):
      #
      # @todo 50: flow sensitive typing needs to handle ivars
      # @todo 13: need to improve handling of &.
      # @todo 8: Should handle redefinition of types in simple contexts
      # @todo 7: need boolish support for ? methods
      # @todo 4: Need to understand .is_a? <not nil> implies not nil
      # @todo 4: flow sensitive typing needs better handling of ||= on lvars
      # @todo 4: @type should override probed type
      # @todo 3: downcast output of Enumerable#select
      # @todo 3: flow sensitive typing needs to handle 'raise if'
      # @todo 2: should warn on nil dereference below
      # @todo 2: Need to look at Tuple#include? handling
      # @todo 2: Should better support meaning of '&' in RBS
      # @todo 2: flow sensitive typing needs to handle "if foo = bar"
      # @todo 1: flow sensitive typing needs to create separate ranges for postfix if
      # @todo 1: flow sensitive typing handling else from is_a? with union types
      # @todo 1: flow sensitive typing needs to handle constants
      # @todo 1: To make JSON strongly typed we'll need a record syntax
      # @todo 1: foo = 1; foo = 2 if bar? should be of type 'Integer', not 'Integer, nil'
      # @todo 1: flow sensitive typing needs to eliminate literal from union with return if foo == :bar
      # @todo 1: flow sensitive typing needs to eliminate literal from union with [:bar].include?(foo)
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
