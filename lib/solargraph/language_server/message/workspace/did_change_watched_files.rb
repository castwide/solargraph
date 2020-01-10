# frozen_string_literal: true

module Solargraph::LanguageServer::Message::Workspace
  class DidChangeWatchedFiles < Solargraph::LanguageServer::Message::Base
    CREATED = 1
    CHANGED = 2
    DELETED = 3

    include Solargraph::LanguageServer::UriHelpers

    def process
      need_catalog = false
      # @param change [Hash]
      params['changes'].each do |change|
        if change['type'] == CREATED
          host.create change['uri']
          need_catalog = true
        elsif change['type'] == CHANGED
          next if host.open?(change['uri'])
          host.create change['uri']
          need_catalog = true
        elsif change['type'] == DELETED
          host.delete change['uri']
          need_catalog = true
        else
          set_error Solargraph::LanguageServer::ErrorCodes::INVALID_PARAMS, "Unknown change type ##{change['type']} for #{uri_to_file(change['uri'])}"
        end
      end
      # Force host to catalog libraries after file changes (see castwide/solargraph#139)
      host.catalog if need_catalog
    end
  end
end
