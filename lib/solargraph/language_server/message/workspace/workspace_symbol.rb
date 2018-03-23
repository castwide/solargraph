class Solargraph::LanguageServer::Message::Workspace::WorkspaceSymbol < Solargraph::LanguageServer::Message::Base
  include Solargraph::LanguageServer::UriHelpers

  def process
    pins = host.api_map.query_symbols(params['query'])
    info = pins.map do |pin|
      parts = pin.location.split(':')
      char = parts.pop.to_i
      line = parts.pop.to_i
      filename = parts.join(':')
      {
        name: pin.path,
        kind: Solargraph::LanguageServer::SymbolKinds::NAMESPACE,
        location: {
          uri: file_to_uri(filename),
          range: {
            start: {
              line: line,
              character: char
            },
            end: {
              line: line,
              character: char
            }
          }
        }
      }
    end
    set_result info
  end
end
