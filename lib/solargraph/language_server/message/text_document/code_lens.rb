# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class CodeLens < Base
          def process
            set_result host.code_lenses(params['textDocument']['uri']).map(&:to_hash)
          end
        end
      end
    end
  end
end
