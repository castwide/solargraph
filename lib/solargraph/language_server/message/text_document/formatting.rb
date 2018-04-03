require 'open3'

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class Formatting < Base
          def process
            filename = uri_to_file(params['textDocument']['uri'])
            original = host.read_text(params['textDocument']['uri'])
            cmd = "rubocop -a -f fi -s #{Shellwords.escape(filename)}"
            o, e, s = Open3.capture3(cmd, stdin_data: original)
            formatted = o.lines[2..-1].join
            set_result(
              [
                {
                  range: {
                    start: {
                      line: 0,
                      character: 0
                    },
                    end: {
                      line: original.lines.length,
                      character: 0
                    }
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
