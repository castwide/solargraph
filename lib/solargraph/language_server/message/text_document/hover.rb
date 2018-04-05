require 'uri'

module Solargraph::LanguageServer::Message::TextDocument
  class Hover < Base
    def process
      filename = uri_to_file(params['textDocument']['uri'])
      line = params['position']['line']
      col = params['position']['character']
      suggestions = host.definitions_at(filename, line, col)
      # contents = suggestions.map(&:hover)
      contents = []
      last_return_type = nil
      suggestions.each do |pin|
        parts = []
        if !pin.return_type.nil? and pin.return_type != last_return_type
          parts.push link_documentation(pin.return_type)
        end
        parts.push pin.documentation unless pin.documentation.nil? or pin.documentation.empty?
        contents.push parts.join("\n\n") unless parts.empty?
        last_return_type = pin.return_type
      end
      set_result(
        contents: {
          kind: 'markdown',
          value: contents.join("\n\n")
        }
      )
    end

    private

    # @todo: DRY this method. It exists in Conversions
    def link_documentation path
      uri = "solargraph:/document?query=" + URI.encode(path)
      "[#{path}](#{uri})"
    end  
  end
end
