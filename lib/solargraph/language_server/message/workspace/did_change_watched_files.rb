require 'uri'

module Solargraph::LanguageServer::Message::Workspace
  class DidChangeWatchedFiles < Solargraph::LanguageServer::Message::Base
    CREATED = 1
    CHANGED = 2
    DELETED = 3

    include Solargraph::LanguageServer::UriHelpers

    def process
      return # @todo Fix this
      params['changes'].each do |change|
        if change['type'] == CREATED
          host.create uri
        elsif change['type'] == CHANGED
          # @todo Should this check if the source is already loaded in the source?
          # Possibly out of sync with the disk?
          # host.workspace.handle_changed filename
          # host.api_map.refresh
          STDERR.puts "TODO: Workspace changed"
        elsif change['type'] == DELETED
          host.delete uri
        else
          # @todo Handle error
        end
      end
    end
  end
end
