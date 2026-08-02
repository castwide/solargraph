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
      # @param overrides [Hash{Symbol => Symbol}]
      def initialize level, overrides
        @rank = if LEVELS.key?(level)
                  LEVELS[level]
                else
                  Solargraph.logger.warn "Unrecognized TypeChecker level #{level}, assuming normal"
                  0
                end
        @level = LEVELS[LEVELS.values.index(@rank)]
        @overrides = overrides
      end

      def ignore_all_undefined?
        !report_undefined?
      end

      def report_undefined?
        report?(:report_undefined, :strict)
      end

      def validate_consts?
        report?(:validate_consts, :strict)
      end

      def validate_calls?
        report?(:validate_calls, :strict)
      end

      def require_type_tags?
        report?(:validate_type_tags, :strong)
      end

      def must_tag_or_infer?
        report?(:must_tag_or_infer, :strict)
      end

      def validate_tags?
        report?(:validate_tags, :typed)
      end

      def require_inferred_type_params?
        report?(:require_inferred_type_params, :alpha)
      end

      #
      # False negatives:
      #
      # @todo 3: Missed nil violation
      #
      # pending code fixes (605):
      #
      # @todo 433: Need to add nil check here
      # @todo 79: https://github.com/castwide/solargraph/pull/1223
      # @todo 50: https://github.com/castwide/solargraph/pull/1245
      # @todo 26: Translate to something flow sensitive typing understands
      # @todo 17: Need a downcast here
      #
      # flow sensitive typing could handle (161):
      #
      # @todo 30: flow sensitive typing needs to handle attrs
      # @todo 20: flow sensitive typing should be able to handle redefinition
      # @todo 16: flow sensitive typing should support case/when
      # @todo 12: flow sensitive typing needs to narrow down type with an if is_a? check
      # @todo 12: flow based typing needs to understand case when class pattern
      # @todo 11: flow sensitive typing needs better handling of ||= on lvars
      # @todo 11: Need to validate config
      # @todo 8: flow sensitive typing should support .class == .class
      # @todo 5: need boolish support for ? methods
      # @todo 4: flow sensitive typing ought to be able to handle 'when ClassName'
      # @todo 4: literal arrays in this module turn into ::Solargraph::Source::Chain::Array
      # @todo 4: flow sensitive typing needs to handle 'raise if'
      # @todo 2: flow sensitive typing should handle is_a? and next
      # @todo 2: flow sensitive typing needs to handle "if foo = bar"
      # @todo 2: flow sensitive typing needs to create separate ranges for postfix if
      # @todo 2: Need better handling of #compact
      # @todo 2: downcast output of Enumerable#select
      # @todo 1: flow sensitive typing should support ivars
      # @todo 1: Need to be able to resolve generics based on a
      # @todo 1: Need to support this in flow sensitive typing
      # @todo 1: flow sensitive typing needs to handle "if foo.nil?"
      # @todo 1: flow sensitive typing should be able to identify more blocks that always return
      # @todo 1: flow sensitive typing needs to eliminate literal from union with return if foo == :bar
      # @todo 1: flow sensitive typing not smart enough to handle this case
      # @todo 1: flow sensitive typing needs to handle self.class == other.class
      # @todo 1: flow-sensitive typing should be able to handle redefinition
      # @todo 1: flow sensitive typing needs to eliminate literal from union with [:bar].include?(foo)
      # @todo 1: Should better support meaning of '&' in RBS
      # @todo 1: flow sensitive typing needs to handle constants
      # @todo 1: Need to handle duck-typed method calls on union types
      # @todo 1: flow sensitive typing needs to remove literal with
      def require_all_unique_types_match_expected?
        report?(:require_all_unique_types_match_expected, :strong)
      end

      def require_all_unique_types_support_call?
        report?(:require_all_unique_types_support_call, :strong)
      end

      def require_no_undefined_args?
        report?(:require_no_undefined_args, :alpha)
      end

      def require_generics_resolved?
        report?(:require_generics_resolved, :alpha)
      end

      def require_interfaces_resolved?
        report?(:require_interfaces_resolved, :alpha)
      end

      def require_downcasts?
        report?(:require_downcasts, :alpha)
      end

      # We keep this at strong because if you added an @ sg-ignore to
      # address a strong-level issue, then ran at a lower level, you'd
      # get a false positive - we don't run stronger level checks than
      # requested for performance reasons
      def validate_sg_ignores?
        report?(:validate_sg_ignores, :strong)
      end

      private

      # @param type [Symbol]
      # @param level [Symbol]
      def report? type, level
        rank >= LEVELS[@overrides.fetch(type, level)]
      end
    end
  end
end
