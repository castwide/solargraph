require 'thread'

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class DidChange < Base
          def process
            host.change filename, params['contentChanges']
            publish_diagnostics
          end
        end
      end
    end
  end
end
