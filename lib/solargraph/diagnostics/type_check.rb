# frozen_string_literal: true

module Solargraph
  module Diagnostics
    # TypeCheck reports methods with undefined return types, untagged
    # parameters, and invalid param tags.
    #
    class TypeCheck < Base
      # @return [Array<Hash>]
      def diagnose source, api_map
        # return [] unless args.include?('always') || api_map.workspaced?(source.filename)
        severity = Diagnostics::Severities::ERROR
        level = args.reverse.find { |a| %w[normal typed strict strong].include?(a) } || 'normal'
        checker = Solargraph::TypeChecker.new(source.filename, api_map: api_map, level: level.to_sym)
        sorted = checker.problems.sort_by do |problem|
          location = problem.location
          location.nil? ? 0 : location.range.start.line
        end
        sorted.map do |problem|
          location = problem.location
          {
            range: location.nil? ? Solargraph::Range.from_to(0, 0, 0, 0).to_hash : extract_first_line(location, source),
            severity: severity,
            source: 'Typecheck',
            message: problem.message
          }
        end
      end

      private

      # @param location [Location]
      # @param source [Source]
      # @return [Hash]
      def extract_first_line location, source
        return location.range.to_hash if location.range.start.line == location.range.ending.line
        {
          start: {
            line: location.range.start.line,
            character: location.range.start.character
          },
          end: {
            line: location.range.start.line,
            character: last_character(location.range.start, source)
          }
        }
      end

      # @param position [Solargraph::Position]
      # @param source [Solargraph::Source]
      # @return [Integer]
      def last_character position, source
        cursor = Position.to_offset(source.code, position)
        source.code.index(/[\r\n]/, cursor) || source.code.length
      end
    end
  end
end
