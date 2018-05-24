require 'uri'

module Solargraph::LanguageServer::Message::TextDocument
  class Hover < Base
    def process
      filename = uri_to_file(params['textDocument']['uri'])
      line = params['position']['line']
      col = params['position']['character']
      contents = []
      suggestions = host.definitions_at(filename, line, col)
      last_path = nil
      suggestions.each do |pin|
        parts = []
        this_path = nil
        if pin.kind_of?(Solargraph::Pin::BaseVariable)
          this_path = pin.return_type
        else
          this_path = pin.path
        end
        if !this_path.nil? and this_path != last_path
          parts.push link_documentation(this_path)
        end
        parts.push pin.documentation unless pin.documentation.nil? or pin.documentation.empty?
        contents.push parts.join("\n\n") unless parts.empty?
        last_path = this_path unless this_path.nil?
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
