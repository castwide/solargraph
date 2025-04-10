# frozen_string_literal: true

module Solargraph
  module LanguageServer
    class Host
      # Methods for associating sources with libraries via URIs.
      #
      module Dispatch
        # @abstract
        # @return [Host::Diagnoser]
        def diagnoser
          raise NotImplementedError, 'Host::Dispatch requires a diagnoser method'
        end

        # @return [Sources]
        def sources
          @sources ||= begin
            src = Sources.new
            src.add_observer self, :update_libraries
            src
          end
        end

        # @return [::Array<Library>]
        def libraries
          @libraries ||= []
        end

        # The Sources observer callback that merges a source into the host's
        # libraries when it gets updated.
        #
        # @param uri [String]
        # @return [void]
        def update_libraries uri
          src = sources.find(uri)
          using = libraries.select { |lib| lib.contain?(src.filename) }
          using.push library_for(uri) if using.empty?
          using.each { |lib| lib.merge src }
          diagnoser.schedule uri
        end

        # Find the best libary match for the given URI.
        #
        # @param uri [String]
        # @return [Library]
        def library_for uri
          result = explicit_library_for(uri) ||
            implicit_library_for(uri) ||
            generic_library_for(uri)
          # previous library for already call attach. avoid call twice
          # result.attach sources.find(uri) if sources.include?(uri)
          result
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
            if filename.start_with?(lib.workspace.directory)
              lib.attach sources.find(uri)
              return lib
            end
          end
          nil
        end

        def options
          @options ||= {}.freeze
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
          @generic_library ||= Solargraph::Library.new(Solargraph::Workspace.new('', nil, options), nil)
                                                  .tap { |lib| lib.add_observer self }
        end

        # @param library [Solargraph::Library]
        # @return [void]
        def update progress
          progress&.send(self)
        end
      end
    end
  end
end
