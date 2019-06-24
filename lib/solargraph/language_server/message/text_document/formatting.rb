require 'open3'
require 'shellwords'

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class Formatting < Base
          def process
            filename = uri_to_file(params['textDocument']['uri'])
            filename = 'tmp.rb' if filename.nil? or filename.empty?
            original = host.read_text(params['textDocument']['uri'])
            cmd = "rubocop -a -f fi -s #{Shellwords.escape(filename)}"
            o, e, s = Open3.capture3(cmd, stdin_data: original)
            return format(original, o) if o && !o.empty?
            set_error(Solargraph::LanguageServer::ErrorCodes::INTERNAL_ERROR, e)
          end

          def format original, result
            lines = result.lines
            index = lines.index{|l| l.start_with?('====================')}
            formatted = lines[index+1..-1].join
            # The response is required to send an explicit range. Text edits
            # with null ranges get ignored. See castwide/vscode-solargraph#83
            if original.end_with?("\n")
              ending = {
                line: original.lines.length,
                character: 0
              }
            else
              ending = {
                line: original.lines.length - 1,
                character: original.lines.last.length
              }
            end
            set_result(
              [
                {
                  range: {
                    start: {
                      line: 0,
                      character: 0
                    },
                    end: ending
                  },
                  newText: formatted
                }
              ]
            )
          end
        end
      end
    end
  end
end
