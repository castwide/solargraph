module Solargraph
  module LanguageServer
    class Host
      class Sources
        include UriHelpers

        def open uri, text, version
          filename = uri_to_file(uri)
          source = Solargraph::Source.new(text, filename, version)
          open_source_hash[uri] = source
        end

        def update uri, updater
          src = find(uri)
          open_source_hash[uri] = src.synchronize(updater)
        end

        # @return [Source]
        def find uri
          open_source_hash[uri] || raise(Solargraph::FileNotFoundError, "Host could not find #{uri}")
        end

        def close uri
          open_source_hash.delete uri
        end

        def include? uri
          open_source_hash.key? uri
        end

        private

        def open_source_hash
          @open_source_hash ||= {}
        end
      end
    end
  end
end
