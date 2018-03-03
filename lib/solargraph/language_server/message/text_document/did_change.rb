require 'thread'

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class DidChange < Base
          def process
            host.change params
            publish_diagnostics
          end
        end
      end
    end
  end
end
