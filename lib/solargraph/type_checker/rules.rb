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

      # @todo 27: Need to understand @foo ||= 123 will never be nil
      # @todo 18: Need to add nil check here
      # @todo 16: flow sensitive typing needs to handle "if foo.nil?"
      # @todo 15: flow sensitive typing needs to handle "if foo"
      # @todo 15: flow sensitive typing needs to handle || on nil types
      # @todo 7: Need to figure if String#[n..m] can return nil
      # @todo 6: Need to validate config
      # @todo 5: need boolish support for ? methods
      # @todo 4: Need to figure if Array#[n..m] can return nil
      # @todo 1: To make JSON strongly typed we'll need a record syntax
      # @todo 1: Untyped method Solargraph::Pin::Base#assert_same could not be inferred
      def require_all_unique_types_match_expected?
        rank >= LEVELS[:typed]
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
