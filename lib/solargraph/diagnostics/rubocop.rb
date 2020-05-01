# frozen_string_literal: true

require 'rubocop'
require 'stringio'

module Solargraph
  module Diagnostics
    # This reporter provides linting through RuboCop.
    #
    class Rubocop < Base
      include RubocopHelpers

      # Conversion of RuboCop severity names to LSP constants
      SEVERITIES = {
        'refactor' => Severities::HINT,
        'convention' => Severities::INFORMATION,
        'warning' => Severities::WARNING,
        'error' => Severities::ERROR,
        'fatal' => Severities::ERROR
      }

      # @param source [Solargraph::Source]
      # @param _api_map [Solargraph::ApiMap]
      # @return [Array<Hash>]
      def diagnose source, _api_map
        options, paths = generate_options(source.filename, source.code)
        store = RuboCop::ConfigStore.new
        runner = RuboCop::Runner.new(options, store)
        result = redirect_stdout{ runner.run(paths) }
        make_array JSON.parse(result)
      rescue RuboCop::ValidationError, RuboCop::ConfigNotFoundError => e
        raise DiagnosticsError, "Error in RuboCop configuration: #{e.message}"
      rescue JSON::ParserError
        raise DiagnosticsError, 'RuboCop returned invalid data'
      end

      private

      # @param resp [Hash]
      # @return [Array<Hash>]
      def make_array resp
        diagnostics = []
        resp['files'].each do |file|
          file['offenses'].each do |off|
            diagnostics.push offense_to_diagnostic(off)
          end
        end
        diagnostics
      end

      # Convert a RuboCop offense to an LSP diagnostic
      #
      # @param off [Hash] Offense received from Rubocop
      # @return [Hash] LSP diagnostic
      def offense_to_diagnostic off
        {
          range: offense_range(off).to_hash,
          # 1 = Error, 2 = Warning, 3 = Information, 4 = Hint
          severity: SEVERITIES[off['severity']],
          source: off['cop_name'],
          message: off['message'].gsub(/^#{off['cop_name']}\:/, '')
        }
      end

      # @param off [Hash]
      # @return [Range]
      def offense_range off
        Range.new(offense_start_position(off), offense_ending_position(off))
      end

      # @param off [Hash]
      # @return [Position]
      def offense_start_position off
        Position.new(off['location']['start_line'] - 1, off['location']['start_column'] - 1)
      end

      # @param off [Hash]
      # @return [Position]
      def offense_ending_position off
        if off['location']['start_line'] != off['location']['last_line']
          Position.new(off['location']['start_line'], 0)
        else
          Position.new(
            off['location']['start_line'] - 1, off['location']['last_column']
          )
        end
      end
    end
  end
end
