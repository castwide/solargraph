require 'rubygems'

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
            begin
              fetcher = Gem::SpecFetcher.new
              tuple = fetcher.search_for_dependency(Gem::Dependency.new('solargraph')).flatten.first
              if tuple.nil?
                msg = 'An error occurred checking the Solargraph gem version.'
                STDERR.puts msg
                host.show_message(msg, MessageTypes::ERROR)
              else
                available = Gem::Version.new(tuple.version)
                current = Gem::Version.new(Solargraph::VERSION)
                if available > current
                  host.show_message_request "Solargraph gem version #{available} is available.",
                                            LanguageServer::MessageTypes::INFO,
                                            ['Update now'] do |result|
                                              next unless result == 'Update now'
                                              o, s = Open3.capture2("gem update solargraph")
                                              if s == 0
                                                host.show_message 'Successfully updated the Solargraph gem.', LanguageServer::MessageTypes::INFO
                                                host.send_notification '$/solargraph/restart', {}
                                              else
                                                host.show_message 'An error occurred while updating the gem.', LanguageServer::MessageTypes::ERROR
                                              end
                                            end
                elsif params['verbose']
                  host.show_message "The Solargraph gem is up to date (version #{Solargraph::VERSION})."
                end
                set_result({
                  installed: current,
                  available: available
                })
              end
            rescue Errno::EADDRNOTAVAIL => e
              msg = "Unable to connect to gem source: #{e.message}"
              STDERR.puts msg
              host.show_message(msg, MessageTypes::ERROR) if params['verbose']
            end
          end
        end
      end
    end
  end
end
