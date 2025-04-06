# frozen_string_literal: true

require 'observer'

module Solargraph
  module LanguageServer
    class Host
      # A Host class for managing sources.
      #
      class Sources
        include Observable
        include UriHelpers

        # @param uri [String]
        # @return [void]
        def add_uri(uri)
          queue.push(uri)
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

        # @param uri [String]
        # @return [void]
        def open_from_disk uri
          source = Solargraph::Source.load(UriHelpers.uri_to_file(uri))
          open_source_hash[uri] = source
        end

        # Update an existing source.
        #
        # @raise [FileNotFoundError] if the URI does not match an open source.
        #
        # @param uri [String]
        # @param updater [Source::Updater]
        # @return [void]
        def update uri, updater
          src = find(uri)
          open_source_hash[uri] = src.synchronize(updater)
          changed
          notify_observers uri
        end

        # Find the source with the given URI.
        #
        # @raise [FileNotFoundError] if the URI does not match an open source.
        #
        # @param uri [String]
        # @return [Solargraph::Source]
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

        # @return [Hash{String => Solargraph::Source}]
        def open_source_hash
          @open_source_hash ||= {}
        end

        # An array of source URIs that are waiting to finish synchronizing.
        #
        # @return [::Array<String>]
        def queue
          @queue ||= []
        end
      end
    end
  end
end
