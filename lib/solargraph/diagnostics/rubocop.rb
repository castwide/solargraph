require 'open3'
require 'shellwords'

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

      # The rubocop command
      #
      # @return [String]
      attr_reader :command

      def initialize(command = 'rubocop')
        @command = command
      end

      # @param source [Solargraph::Source]
      # @param api_map [Solargraph::ApiMap]
      # @return [Array<Hash>]
      def diagnose source, api_map
        begin
          text = source.code
          filename = source.filename
          raise DiagnosticsError, 'No command specified' if command.nil? or command.empty?
          cmd = "#{Shellwords.escape(command)} -f j"
          unless api_map.workspace.nil? or api_map.workspace.directory.nil?
            rc = File.join(api_map.workspace.directory, '.rubocop.yml')
            cmd += " -c #{Shellwords.escape(fix_drive_letter(rc))}" if File.file?(rc)
          end
          cmd += " -s #{Shellwords.escape(fix_drive_letter(filename))}"
          o, e, s = Open3.capture3(cmd, stdin_data: text)
          STDERR.puts e unless e.empty?
          raise DiagnosticsError, "Command '#{command}' is not available (gem exception)" if e.include?('Gem::Exception')
          raise DiagnosticsError, "RuboCop returned empty data" if o.empty?
          make_array JSON.parse(o)
        rescue JSON::ParserError
          raise DiagnosticsError, 'RuboCop returned invalid data'
        rescue Errno::ENOENT
          raise DiagnosticsError, "Command '#{command}' is not available"
        end
      end

      private

      def make_array resp
        diagnostics = []
        resp['files'].each do |file|
          file['offenses'].each do |off|
            if off['location']['start_line'] != off['location']['last_line']
              last_line = off['location']['start_line']
              last_column = 0
            else
              last_line = off['location']['last_line'] - 1
              last_column = off['location']['last_column']
            end
            diag = {
              range: {
                start: {
                  line: off['location']['start_line'] - 1,
                  character: off['location']['start_column'] - 1
                },
                end: {
                  line: last_line,
                  character: last_column
                }
              },
              # 1 = Error, 2 = Warning, 3 = Information, 4 = Hint
              severity: SEVERITIES[off['severity']],
              source: off['cop_name'],
              message: off['message'].gsub(/^#{off['cop_name']}\:/, '')
            }
            diagnostics.push diag
          end
        end
        diagnostics
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
