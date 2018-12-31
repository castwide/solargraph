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

        # Find the best libary match for the given URI.
        #
        # @param uri [String]
        # @return [Library]
        def library_for uri
          explicit_library_for(uri) ||
            implicit_library_for(uri) ||
            generic_library_for(uri)
        end

        # Find an explicit library match for the given URI. An explicit match
        # means the libary's workspace includes the file.
        #
        # If a matching library is found, the source corresponding to the URI
        # gets attached to it.
        #
        # @raise [FileNotFoundError] if the source could not be attached.
        #
        # @param uri [String]
        # @return [Library, nil]
        def explicit_library_for uri
          filename = UriHelpers.uri_to_file(uri)
          libraries.each do |lib|
            if lib.contain?(filename)
              lib.attach sources.find(uri) if sources.include?(uri)
              return lib
            end
          end
          nil
        end

        # Find an implicit library match for the given URI. An implicit match
        # means the file is located inside the library's workspace directory,
        # regardless of whether the workspace is configured to include it.
        #
        # If a matching library is found, the source corresponding to the URI
        # gets attached to it.
        #
        # @raise [FileNotFoundError] if the source could not be attached.
        #
        # @param uri [String]
        # @return [Library, nil]
        def implicit_library_for uri
          filename = UriHelpers.uri_to_file(uri)
          libraries.each do |lib|
            # @todo We probably shouldn't depend on attachments to select
            #   a library.
            # return lib if lib.open?(filename)
            if filename.start_with?(lib.workspace.directory)
              lib.attach sources.find(uri)
              return lib
            end
          end
          nil
        end

        # Get a generic library for the given URI and attach the corresponding
        # source.
        #
        # @raise [FileNotFoundError] if the source could not be attached.
        #
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
