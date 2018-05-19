module Solargraph::LanguageServer::Message::TextDocument
  class References < Base
    def process
      definition = host.definitions_at(uri_to_file(params['textDocument']['uri']), params['position']['line'], params['position']['character']).first
      return if definition.nil?
      locs = host.references_from(uri_to_file(params['textDocument']['uri']), params['position']['line'], params['position']['character'])
      locs.keep_if do |loc|
        referenced = host.definitions_at(loc.filename, loc.range.ending.line, loc.range.ending.character).first
        !referenced.nil? and referenced.path == definition.path
      end
      locs.unshift definition.location if params['context'] and params['context']['includeDeclaration'] and definition.kind == Solargraph::Pin::METHOD and !definition.location.nil?
      result = locs.map do |loc|
        {
          uri: file_to_uri(loc.filename),
          range: loc.range.to_hash
        }
      end
      set_result result
    end
  end
end
