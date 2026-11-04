# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class DocumentSymbol < Solargraph::LanguageServer::Message::Base
          include Solargraph::LanguageServer::UriHelpers

          def process
            pins = host.document_symbols params['textDocument']['uri']
            info = pins.map do |pin|
              loc = pin.best_location
              next if loc.nil? || loc.filename.nil?

              result = {
                name: pin.name,
                containerName: pin.namespace,
                kind: pin.symbol_kind,
                location: {
                  uri: file_to_uri(loc.filename),
                  range: loc.range.to_hash
                },
                deprecated: pin.deprecated?
              }
              result
            end.compact

            set_result info
          end
        end
      end
    end
  end
end
