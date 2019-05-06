require 'uri'

module Solargraph::LanguageServer::Message::Workspace
  class DidChangeWatchedFiles < Solargraph::LanguageServer::Message::Base
    CREATED = 1
    CHANGED = 2
    DELETED = 3

    include Solargraph::LanguageServer::UriHelpers

    def process
      # @param change [Hash]
      params['changes'].each do |change|
        # @todo Changes might need to be handled here even if the file is open
        if change['type'] == CREATED
          host.create change['uri'] #unless host.open?(change['uri'])
        elsif change['type'] == CHANGED
          host.create change['uri'] #unless host.open?(change['uri'])
        elsif change['type'] == DELETED
          host.delete change['uri']
        else
          set_error Solargraph::LanguageServer::ErrorCodes::INVALID_PARAMS, "Unknown change type ##{change['type']} for #{uri_to_file(change['uri'])}"
        end
      end
      # Force host to catalog libraries after file changes (see castwide/solargraph#139)
      host.catalog
    end
  end
end
