require 'uri'

module Solargraph::LanguageServer::Message::Workspace
  class DidChangeConfiguration < Solargraph::LanguageServer::Message::Base
    def process
      host.configure params['settings']['solargraph']
    end
  end
end
