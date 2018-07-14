class Solargraph::LanguageServer::Message::TextDocument::DocumentSymbol < Solargraph::LanguageServer::Message::Base
  include Solargraph::LanguageServer::UriHelpers

  def process
    pins = host.file_symbols params['textDocument']['uri']
    info = pins.reject{|pin| pin.name.empty?}.map do |pin|
      result = {
        name: pin.name,
        containerName: pin.namespace,
        kind: pin.symbol_kind,
        location: {
          uri: file_to_uri(pin.location.filename),
          range: pin.location.range.to_hash
        }
      }
      result
    end
    set_result info
  end
end
