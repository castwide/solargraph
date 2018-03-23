require 'uri'

module Solargraph::LanguageServer::Message::Workspace
  class DidChangeWatchedFiles < Solargraph::LanguageServer::Message::Base
    CREATED = 1
    CHANGED = 2
    DELETED = 3

    include Solargraph::LanguageServer::UriHelpers

    def process
      params['changes'].each do |change|
        filename = uri_to_file(change['uri'])
        if change['type'] == CREATED
          host.workspace.handle_created filename
          host.api_map.refresh
        elsif change['type'] == CHANGED
          # @todo Should this check if the source is already loaded in the source?
          # Possibly out of sync with the disk?
          host.workspace.handle_changed filename
          host.api_map.refresh
        elsif change['type'] == DELETED
          host.workspace.handle_deleted filename
          host.api_map.refresh
        else
          # @todo Handle error
        end
      end
    end
  end
end
