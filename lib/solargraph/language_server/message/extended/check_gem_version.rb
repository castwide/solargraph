require 'open3'

module Solargraph
  module LanguageServer
    module Message
      module Extended
        # Check if a more recent version of the Solargraph gem is available.
        # Notify the client when an update exists. If the `verbose` parameter
        # is true, notify the client when the gem is up to date.
        #
        class CheckGemVersion < Base
          def process
            o, s = Open3.capture2("gem search solargraph")
            match = o.match(/solargraph \([0-9\.]*?\)/)
            # @todo Error if no match or status code != 0
            available = Gem::Version.new(match[1])
            current = Gem::Version.new(Solargraph::VERSION)
            if available > current
              host.show_message_request "Solagraph gem version #{available} is available.",
                                        LanguageServer::MessageTypes::INFO,
                                        ['Update now'] { |result|
                                          break unless result == 'Update now'
                                          o, s = Open3.capture2("gem update solargraph")
                                          if s == 0
                                            host.show_message 'Successfully updated the Solargraph gem.', LanguageServer::MessageTypes::INFO
                                          else
                                            host.show_message 'An error occurred while updating the gem.', LanguageServer::MessageTypes::ERROR
                                          end
                                        }
            elsif params['verbose']
              host.show_message "The Solargraph gem is up to date (version #{Solargraph::VERSION})."
            end
          end
        end
      end
    end
  end
end
