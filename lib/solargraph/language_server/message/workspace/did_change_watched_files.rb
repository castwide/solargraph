require 'uri'

module Solargraph::LanguageServer::Message::Workspace
  class DidChangeWatchedFiles < Solargraph::LanguageServer::Message::Base
    CREATED = 1
    CHANGED = 2
    DELETED = 3

    include Solargraph::LanguageServer::UriHelpers

    def process
      STDERR.puts "Handle a workspace change: #{params.inspect}"
      params['changes'].each do |change|
        unless change['type'] == CHANGED
          # source = host.read change['uri']
          # unless source.nil?
          #   if change['type'] == DELETED
          #     STDERR.puts "Delete #{source.filename} from the workspace"
          #   else
          #     STDERR.puts "Update #{source.filename}"
          #   end
          # end
          filename = uri_to_file(change['uri'])
          if change['type'] == CREATED
            STDERR.puts "Creating #{filename}"
            host.workspace.handle_created filename
            host.synchronize { host.api_map.refresh }
          elsif change['type'] == CHANGED
            # @todo Should this check if the source is already loaded in the source?
            # Possibly out of sync with the disk?
          elsif change['type'] == DELETED
            STDERR.puts "Deleting #{filename}"
            host.workspace.handle_deleted filename
            host.synchronize { host.api_map.refresh }
          else
            # @todo Handle error
            STDERR.puts "Invalid change type #{change['type']}"
          end
        end
      end
    end
  end
end
