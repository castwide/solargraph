require 'uri'
require 'htmlentities'

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
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
              parts.push HTMLEntities.new.encode(host.detail(pin)) unless pin.kind == Solargraph::Pin::NAMESPACE or pin.detail.nil?
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
          rescue FileNotFoundError => e
            Logging.logger.warn "[#{e.class}] #{e.message}"
            Logging.logger.warn e.backtrace.join("\n")
            set_result nil
          end
        end
      end
    end
  end
end
