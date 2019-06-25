# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class SignatureHelp < TextDocument::Base
          def process
            line = params['position']['line']
            col = params['position']['character']
            suggestions = host.signatures_at(params['textDocument']['uri'], line, col)
            info = []
            suggestions.each do |pin|
              info.concat pin.overloads.map(&:signature_help)
              info.push pin.signature_help
            end
            set_result({
              signatures: info
            })
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
