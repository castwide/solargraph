module Solargraph
  module LanguageServer
    class Host
      # Methods for associating sources with libraries via URIs.
      #
      module Dispatch
        module_function

        # @return [Sources]
        def sources
          @sources ||= Sources.new
        end

        # @return [Array<Library>]
        def libraries
          @libraries ||= []
        end

        # @param uri [String]
        # @return [Library]
        def library_for uri
          explicit_library_for(uri) ||
            implicit_library_for(uri) ||
            generic_library_for(uri)
        end

        # @param uri [String]
        # @return [Library, nil]
        def explicit_library_for uri
          filename = UriHelpers.uri_to_file(uri)
          libraries.each do |lib|
            if lib.contain?(filename) #|| lib.open?(filename)
              lib.attach sources.find(uri) if sources.include?(uri)
              return lib
            end
          end
          nil
        end

        # @param uri [String]
        # @return [Library, nil]
        def implicit_library_for uri
          filename = UriHelpers.uri_to_file(uri)
          libraries.each do |lib|
            # return lib if filename.start_with?(lib.workspace.directory)
            if lib.open?(filename) || filename.start_with?(lib.workspace.directory)
              lib.attach sources.find(uri)
              return lib
            end
          end
          nil
        end

        # @param uri [String]
        # @return [Library]
        def generic_library_for uri
          generic_library.attach sources.find(uri)
          generic_library
        end

        # @return [Library]
        def generic_library
          @generic_library ||= Solargraph::Library.new
        end
      end
    end
  end
end
