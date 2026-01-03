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

      def require_all_return_types_match_inferred?
        report?(:require_all_return_types_match_inferred, :alpha)
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
