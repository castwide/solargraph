# frozen_string_literal: true

require 'open3'

module Solargraph
  module LanguageServer
    module Message
      module Extended
        # Update YARD documentation for installed gems. If the `rebuild`
        # parameter is true, rebuild existing yardocs.
        #
        class DocumentGems < Base
          def process
            cmd = [host.command_path, 'gems']
            cmd.push '--rebuild' if params['rebuild']
            _, s = Open3.capture2(*cmd)
            if s == 0
              set_result({
                           status: 'ok'
                         })
            else
              host.show_message 'An error occurred while building gem documentation.', LanguageServer::MessageTypes::ERROR
              set_result({
                           status: 'err'
                         })
            end
          end
        end
      end
    end
  end
end
