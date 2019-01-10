require 'uri'
require 'htmlentities'

module Solargraph::LanguageServer::Message::TextDocument
  class Hover < Base
    def process
      filename = uri_to_file(params['textDocument']['uri'])
      line = params['position']['line']
      col = params['position']['character']
      contents = []
      suggestions = host.definitions_at(filename, line, col)
      last_link = nil
      suggestions.each do |pin|
        parts = []
        this_link = pin.link_documentation
        if !this_link.nil? and this_link != last_link
          parts.push this_link
        end
        parts.push HTMLEntities.new.encode(pin.detail) unless pin.kind == Solargraph::Pin::NAMESPACE or pin.detail.nil?
        parts.push pin.documentation unless pin.documentation.nil? or pin.documentation.empty?
        contents.push parts.join("\n\n") unless parts.empty?
        last_link = this_link unless this_link.nil?
      end
      set_result(
        contents: {
          kind: 'markdown',
          value: contents.join("\n\n")
        }
      )
    rescue InvalidOffsetError
      Logging.logger.info "Hover ignored invalid offset: #{filename}, line #{line}, character #{col}"
      set_result nil
    end
  end
end
