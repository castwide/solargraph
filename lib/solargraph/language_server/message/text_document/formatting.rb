require 'open3'

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
            lines = o.lines
            index = lines.index{|l| l.start_with?('====================')}
            formatted = lines[index+1..-1].join
            set_result(
              [
                {
                  range: nil,
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
