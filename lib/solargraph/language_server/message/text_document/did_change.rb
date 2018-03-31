require 'thread'

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class DidChange < Base
          def process
            host.change params
            host.diagnose params['textDocument']['uri']
          end
        end
      end
    end
  end
end
