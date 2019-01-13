require 'observer'

module Solargraph
  module LanguageServer
    class Host
      # A Host class for managing sources.
      #
      class Sources
        include Observable
        include UriHelpers

        def initialize
          @stopped = true
        end

        def stopped?
          @stopped
        end

        # @return [void]
        def start
          return unless @stopped
          @stopped = false
          Thread.new do
            until stopped?
              tick
              sleep 0.25
            end
          end
        end

        # @return [void]
        def tick
          return if queue.empty?
          uri = mutex.synchronize { queue.shift }
          return if queue.include?(uri)
          mutex.synchronize do
            nxt = open_source_hash[uri].finish_synchronize
            open_source_hash[uri] = nxt
            changed
            notify_observers open_source_hash[uri]
          end
        end

        # @return [void]
        def stop
          @stopped = true
        end

        # Open a source.
        #
        # @param uri [String]
        # @param text [String]
        # @param version [Integer]
        # @return [Source]
        def open uri, text, version
          filename = uri_to_file(uri)
          source = Solargraph::Source.new(text, filename, version)
          open_source_hash[uri] = source
        end

        # Update an existing source.
        #
        # @raise [FileNotFoundError] if the URI does not match an open source.
        #
        # @param uri [String]
        # @param updater [Source::Updater]
        # @return [Source]
        def update uri, updater
          src = find(uri)
          # open_source_hash[uri] = src.synchronize(updater)
          mutex.synchronize { open_source_hash[uri] = src.synchronize(updater) }
          changed
          notify_observers open_source_hash[uri]
        end

        # @param uri [String]
        # @param updater [Source::Updater]
        # @return [Thread]
        def async_update uri, updater
          src = find(uri)
          mutex.synchronize { open_source_hash[uri] = src.start_synchronize(updater) }
          mutex.synchronize {queue.push uri}
          changed
          notify_observers open_source_hash[uri]
        end

        # Find the source with the given URI.
        #
        # @raise [FileNotFoundError] if the URI does not match an open source.
        #
        # @param uri [String]
        # @return [Source]
        def find uri
          open_source_hash[uri] || raise(Solargraph::FileNotFoundError, "Host could not find #{uri}")
        end

        # Close the source with the given URI.
        #
        # @param uri [String]
        # @return [void]
        def close uri
          open_source_hash.delete uri
        end

        # True if a source with given URI is currently open.
        # @param uri [String]
        # @return [Boolean]
        def include? uri
          open_source_hash.key? uri
        end

        # @return [void]
        def clear
          open_source_hash.clear
        end

        private

        # @return [Array<Source>]
        def open_source_hash
          @open_source_hash ||= {}
        end

        # @return [Mutex]
        def mutex
          @mutex ||= Mutex.new
        end

        # An array of source URIs that are waiting to finish synchronizing.
        #
        # @return [Array<String>]
        def queue
          @queue ||= []
        end
      end
    end
  end
end
