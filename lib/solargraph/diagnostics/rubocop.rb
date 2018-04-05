require 'open3'
require 'shellwords'

module Solargraph
  module Diagnostics
    class Rubocop
      def initialize
      end

      def diagnose text, filename
        begin
          cmd = "rubocop -f j -s #{Shellwords.escape(filename)}"
          o, e, s = Open3.capture3(cmd, stdin_data: text)
          make_hash text, JSON.parse(o)
        rescue Exception => e
          STDERR.puts "#{e}"
          STDERR.puts "#{e.backtrace}"
          nil
        end
      end

      def make_hash text, resp
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
              last_column = off['location']['last_column'] - 1
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
