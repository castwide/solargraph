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
        if change['type'] == CREATED
          # It's only necessary to create the file from if the file isn't open
          # in the client
          host.create change['uri'] unless host.open?(change['uri'])
        elsif change['type'] == CHANGED
          # It's only necessary to update from here if the file isn't open in
          # the client
          host.create change['uri'] unless host.open?(change['uri'])
        elsif change['type'] == DELETED
          host.delete change['uri']
        else
          set_error Solargraph::LanguageServer::ErrorCodes::INVALID_PARAMS, "Unknown change type ##{change['type']} for #{uri_to_file(change['uri'])}"
        end
      end
    end
  end
end
