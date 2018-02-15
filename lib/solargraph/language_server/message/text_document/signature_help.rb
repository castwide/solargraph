module Solargraph
  module LanguageServer
    module TextDocument
      class SignatureHelp < Base
        def process
          text = host.read(filename)
          code_map = Solargraph::CodeMap.new(code: text, filename: filename, api_map: host.api_map, cursor: [params['position']['line'], params['position']['character']])
          offset = code_map.get_offset(params['position']['line'], params['position']['character'])
          sugg = code_map.signatures_at(offset)
          # @todo: result
        end
      end
    end
  end
end
