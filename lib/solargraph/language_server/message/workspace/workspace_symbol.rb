# frozen_string_literal: true

class Solargraph::LanguageServer::Message::Workspace::WorkspaceSymbol < Solargraph::LanguageServer::Message::Base
  include Solargraph::LanguageServer::UriHelpers

  def process
    pins = host.query_symbols(params['query'])
    info = pins.map do |pin|
      # @sg-ignore Need to add nil check here
      uri = file_to_uri(pin.best_location.filename)
      {
        name: pin.path,
        containerName: pin.namespace,
        kind: pin.symbol_kind,
        location: {
          uri: uri,
          # @sg-ignore Need to add nil check here
          range: pin.best_location.range.to_hash
        },
        deprecated: pin.deprecated?
      }
    end
    set_result info
  end
end
