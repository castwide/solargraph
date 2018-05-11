require 'open3'
require 'shellwords'

module Solargraph
  module Diagnostics
    class Rubocop < Base
      # The rubocop command
      #
      # @return [String]
      attr_reader :command

      def initialize(command = 'rubocop')
        @command = command
      end

      # @return [Array<Hash>]
      def diagnose source, api_map
        begin
          text = source.code
          filename = source.filename
          raise DiagnosticsError, 'No command specified' if command.nil? or command.empty?
          cmd = "#{Shellwords.escape(command)} -f j -s #{Shellwords.escape(filename)}"
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
        # Conversion of RuboCop severity names to LSP constants
        severities = {
          'refactor' => 4,
          'convention' => 3,
          'warning' => 2,
          'error' => 1,
          'fatal' => 1
        }
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
              severity: severities[off['severity']],
              source: off['cop_name'],
              message: off['message'].gsub(/^#{off['cop_name']}\:/, '')
            }
            diagnostics.push diag
          end
        end
        diagnostics
      end
    end
  end
end
