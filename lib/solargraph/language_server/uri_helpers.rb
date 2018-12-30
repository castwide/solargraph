module Solargraph
  module LanguageServer
    # Methods to handle conversions between file URIs and paths.
    #
    module UriHelpers
      module_function

      # Convert a file URI to a path.
      #
      # @param uri [String]
      # @return [String]
      def uri_to_file uri
        URI.decode(uri).sub(/^file\:\/\//, '').sub(/^\/([a-z]\:)/i, '\1')
      end

      # Convert a file path to a URI.
      #
      # @param file [String]
      # @return [String]
      def file_to_uri file
        "file://#{URI.encode(file.gsub(/^([a-z]\:)/i, '/\1')).gsub(/\:/, '%3A')}"
      end
    end
  end
end
