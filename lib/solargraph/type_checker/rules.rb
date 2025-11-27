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

      #
      # False negatives:
      #
      # @todo 4: Missed nil violation
      #
      # pending code fixes (277):
      #
      # @todo 263: Need to add nil check here
      # @todo 9: Need to validate config
      # @todo 3: Translate to something flow sensitive typing understands
      # @todo 2: Need a downcast here
      #
      # flow-sensitive typing could handle (96):
      #
      # @todo 33: flow sensitive typing needs to handle attrs
      # @todo 14: flow sensitive typing needs to handle ivars
      # @todo 9: Should handle redefinition of types in simple contexts
      # @todo 6: need boolish support for ? methods
      # @todo 5: literal arrays in this module turn into ::Solargraph::Source::Chain::Array
      # @todo 4: flow sensitive typing needs better handling of ||= on lvars
      # @todo 4: flow sensitive typing needs to eliminate literal from union with [:bar].include?(foo)
      # @todo 3: downcast output of Enumerable#select
      # @todo 3: flow sensitive typing needs to handle 'raise if'
      # @todo 2: Need to look at Tuple#include? handling
      # @todo 2: Should better support meaning of '&' in RBS
      # @todo 2: (*) flow sensitive typing needs to handle "if foo = bar"
      # @todo 2: Need to handle duck-typed method calls on union types
      # @todo 2: Need typed hashes
      # @todo 1: should warn on nil dereference below
      # @todo 1: flow sensitive typing needs to create separate ranges for postfix if
      # @todo 1: flow sensitive typing needs to handle constants
      # @todo 1: flow sensitive typing needs to handle while
      # @todo 1: flow sensitive typing needs to eliminate literal from union with return if foo == :bar
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
