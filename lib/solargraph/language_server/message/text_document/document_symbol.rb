class Solargraph::LanguageServer::Message::TextDocument::DocumentSymbol < Solargraph::LanguageServer::Message::Base
  include Solargraph::LanguageServer::UriHelpers

  def process
    pins = host.file_symbols params['textDocument']['uri']
    info = pins.map do |pin|
      {
        name: pin.path,
        kind: Solargraph::LanguageServer::SymbolKinds::NAMESPACE,
        location: {
          uri: file_to_uri(pin.location.filename),
          range: pin.location.range.to_hash
        }
      }
    end
    set_result info
  end
end
