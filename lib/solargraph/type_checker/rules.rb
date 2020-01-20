module Solargraph
  class TypeChecker
    class Rules
      LEVELS = {
        normal: 0,
        typed: 1,
        strict: 2,
        strong: 3
      }

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
        rank == LEVELS[:normal]
      end

      def validate_methods?
        rank > LEVELS[:normal]
      end

      def validate_return_tags?
        rank > LEVELS[:normal]
      end

      def require_type_tags?
        rank >= LEVELS[:strict]
      end
    end
  end
end
