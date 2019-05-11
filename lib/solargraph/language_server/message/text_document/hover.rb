require 'uri'
require 'htmlentities'

module Solargraph::LanguageServer::Message::TextDocument
  class Hover < Base
    def process
      line = params['position']['line']
      col = params['position']['character']
      contents = []
      suggestions = host.definitions_at(params['textDocument']['uri'], line, col)
      last_link = nil
      suggestions.each do |pin|
        parts = []
        this_link = pin.link_documentation
        if !this_link.nil? and this_link != last_link
          parts.push this_link
        end
        # parts.push HTMLEntities.new.encode(pin.detail) unless pin.kind == Solargraph::Pin::NAMESPACE or pin.detail.nil?
        unless pin.kind == Solargraph::Pin::NAMESPACE
          more = host.probe({
            'data' => {
              'uri' => params['textDocument']['uri'],
              'path' => pin.path
            },
            'detail' => pin.detail,
            'kind' => pin.completion_item_kind
          })
          parts.push HTMLEntities.new.encode(more) unless more.nil? || more.empty?
        end
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
    end
  end
end
