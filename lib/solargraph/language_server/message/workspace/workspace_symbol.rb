# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      module Workspace
        class WorkspaceSymbol < Solargraph::LanguageServer::Message::Base
          include Solargraph::LanguageServer::UriHelpers

          def process
            pins = host.query_symbols(params['query'])
            info = pins.map do |pin|
              # @sg-ignore pin.location relies on location always resolved
              uri = file_to_uri(pin.best_location.filename)
              {
                name: pin.path,
                containerName: pin.namespace,
                kind: pin.symbol_kind,
                location: {
                  uri: uri,
                  # @sg-ignore pin.location relies on location always resolved
                  range: pin.best_location.range.to_hash
                },
                deprecated: pin.deprecated?
              }
            end
            set_result info
          end
        end
      end
    end
  end
end
