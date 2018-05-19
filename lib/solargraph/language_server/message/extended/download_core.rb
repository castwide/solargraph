require 'open3'

module Solargraph
  module LanguageServer
    module Message
      module Extended
        # Update core Ruby documentation.
        #
        class DownloadCore < Base
          def process
            cmd = "solargraph download-core"
            o, s = Open3.capture2(cmd)
            if s != 0
              host.show_message "An error occurred while downloading documentation.", LanguageServer::MessageTypes::ERROR
            else
              ver = o.match(/[\d]*\.[\d]*\.[\d]*/)[0]
              host.show_message "Downloaded documentation for Ruby #{ver}.", LanguageServer::MessageTypes::INFO
              # @todo YardMap should be refreshed
            end
          end
        end
      end
    end
  end
end
