require 'rubocop'
require 'stringio'

module Solargraph
  module Diagnostics
    # This reporter provides linting through RuboCop.
    #
    class Rubocop < Base
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
        runner = RuboCop::Runner.new(options, RuboCop::ConfigStore.new)
        result = redirect_stdout{ runner.run(paths) }
        make_array JSON.parse(result)
      rescue RuboCop::ValidationError, RuboCop::ConfigNotFoundError => e
        raise DiagnosticsError, "Error in RuboCop configuration: #{e.message}"
      rescue JSON::ParserError
        raise DiagnosticsError, 'RuboCop returned invalid data'
      end

      private

      # @param filename [String]
      # @param code [String]
      # @return [Array]
      def generate_options filename, code
        args = ['-f', 'j']
        rubocop_file = find_rubocop_file(filename)
        args.push('-c', fix_drive_letter(rubocop_file)) unless rubocop_file.nil?
        args.push filename
        options, paths = RuboCop::Options.new.parse(args)
        options[:stdin] = code
        [options, paths]
      end

      # @param filename [String]
      # @return [String, nil]
      def find_rubocop_file filename
        dir = File.dirname(filename)
        until File.dirname(dir) == dir
          here = File.join(dir, '.rubocop.yml')
          return here if File.exist?(here)
          dir = File.dirname(dir)
        end
        nil
      end

      # @todo This is a smelly way to redirect output, but the RuboCop specs do the
      #   same thing.
      # @return [String]
      def redirect_stdout
        redir = StringIO.new
        $stdout = redir
        yield if block_given?
        $stdout = STDOUT
        redir.string
      end

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

      # RuboCop internally uses capitalized drive letters for Windows paths,
      # so we need to convert the paths provided to the command.
      #
      # @param path [String]
      # @return [String]
      def fix_drive_letter path
        return path unless path.match(/^[a-z]:/)
        path[0].upcase + path[1..-1]
      end
    end
  end
end
