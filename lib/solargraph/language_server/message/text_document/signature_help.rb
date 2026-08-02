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
            set_result({
                         signatures: suggestions.flat_map(&:signature_help)
                       })
          rescue FileNotFoundError => e
            Logging.logger.warn "[#{e.class}] #{e.message}"
            # @sg-ignore Need to add nil check here
            Logging.logger.warn e.backtrace.join("\n")
            # @sg-ignore https://github.com/castwide/solargraph/pull/1223
            set_result nil
          end
        end
      end
    end
  end
end
