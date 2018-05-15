module Solargraph::LanguageServer::Message::TextDocument
  class References < Base
    def process
      STDERR.puts "Got: #{params}"
      host.references_from(uri_to_file(params['textDocument']['uri']), params['textDocument']['position']['line'], params['textDocument']['position']['character'])
    end
  end
end
