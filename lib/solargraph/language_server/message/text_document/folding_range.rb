require 'open3'

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class FoldingRange < Base
          def process
            STDERR.puts "Asking for folding ranges"
            result = host.folding_ranges(params['textDocument']['uri']).map do |range|
              {
                startLine: range.start.line,
                startCharacter: range.start.character,
                endLine: range.ending.line,
                endCharacter: range.ending.character,
                kind: 'region'
              }
            end
            set_result result
          end
        end
      end
    end
  end
end
