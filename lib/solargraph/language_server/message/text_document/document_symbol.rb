# frozen_string_literal: true

class Solargraph::LanguageServer::Message::TextDocument::DocumentSymbol < Solargraph::LanguageServer::Message::Base
  include Solargraph::LanguageServer::UriHelpers

  def process
    pins = host.document_symbols params['textDocument']['uri']
    info = pins.map do |pin|
      next nil unless pin.best_location&.filename

      result = {
        name: pin.name,
        containerName: pin.namespace,
        kind: pin.symbol_kind,
        location: {
          uri: file_to_uri(pin.best_location.filename),
          range: pin.best_location.range.to_hash
        },
        deprecated: pin.deprecated?
      }
      result
    end.compact

    set_result info
  end
end
