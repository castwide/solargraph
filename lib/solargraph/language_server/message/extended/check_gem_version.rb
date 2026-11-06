# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      module Extended
        # Check if a more recent version of the Solargraph gem is available.
        # Notify the client when an update exists. If the `verbose` parameter
        # is true, notify the client when the gem is up to date.
        #
        class CheckGemVersion < Base
          # @return [Gem::SpecFetcher]
          def self.fetcher
            @fetcher ||= Gem::SpecFetcher.new
          end

          # @param obj [Gem::SpecFetcher]
          # @return [Gem::SpecFetcher]
          class << self
            attr_writer :fetcher
          end

          GEM_ZERO = Gem::Version.new('0.0.0')

          # @param host [Solargraph::LanguageServer::Host]
          # @param request [Hash]
          # @param current [Gem::Version]
          # @param available [Gem::Version, nil]
          def initialize host, request, current: Gem::Version.new(Solargraph::VERSION), available: nil
            super(host, request)
            @current = current
            @available = available
          end

          def process
            if available > GEM_ZERO
              if available > current
                host.show_message_request "Solargraph gem version #{available} is available. (Current version: #{current})",
                                          LanguageServer::MessageTypes::INFO,
                                          ['Update now'] do |result|
                                            next unless result == 'Update now'
                                            cmd = if host.options['useBundler']
                                                    'bundle update solargraph'
                                                  else
                                                    'gem update solargraph'
                                                  end
                                            _, s = Open3.capture2(cmd)
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
            elsif fetched?
              # fetch_available sets an error whenever it finds no version
              message = fetch_error
              Solargraph::Logging.logger.warn message
              host.show_message(message, MessageTypes::ERROR) if message && params['verbose']
            end
            set_result({
                         installed: current,
                         available: available
                       })
          end

          private

          # @return [Gem::Version]
          attr_reader :current

          # @return [Gem::Version]
          def available
            @available ||= begin
              @fetched = true
              fetch_available
            end
          end

          # @return [Gem::Version]
          def fetch_available
            # [[[name_tuple, source], ...], [fetch_problem, ...]]
            found = CheckGemVersion.fetcher.search_for_dependency(Gem::Dependency.new('solargraph')).flatten
            tuple = found.grep(Gem::NameTuple).first
            return tuple.version if tuple

            problem = found.grep(Gem::SourceFetchProblem).first
            @fetch_error = problem ? "Unable to connect to gem source: #{problem.wordy}" : 'An error occurred fetching the gem data'
            GEM_ZERO
          rescue Errno::EADDRNOTAVAIL => e
            @fetch_error = "Unable to connect to gem source: #{e.message}"
            GEM_ZERO
          end

          def fetched?
            @fetched ||= false
          end

          # @return [String, nil]
          attr_reader :fetch_error
        end
      end
    end
  end
end
