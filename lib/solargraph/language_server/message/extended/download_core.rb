# frozen_string_literal: true

require 'open3'

module Solargraph
  module LanguageServer
    module Message
      module Extended
        # Update core Ruby documentation.
        #
        class DownloadCore < Base
          def process
            ver = Solargraph::YardMap::CoreDocs.best_download
            Solargraph::YardMap::CoreDocs.download ver
            host.show_message "Downloaded documentation for Ruby #{ver}.", LanguageServer::MessageTypes::INFO
          rescue StandardError => e
            host.show_message "An error occurred while downloading documentation: [#{e.class}] #{e.message}", LanguageServer::MessageTypes::ERROR
          end
        end
      end
    end
  end
end
