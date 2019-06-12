require 'observer'
require 'set'

module Solargraph
  module LanguageServer
    # The language server protocol's data provider. Hosts are responsible for
    # querying the library and processing messages. They also provide thread
    # safety for multi-threaded transports.
    #
    class Host
      autoload :Diagnoser, 'solargraph/language_server/host/diagnoser'
      autoload :Cataloger, 'solargraph/language_server/host/cataloger'
      autoload :Sources,   'solargraph/language_server/host/sources'
      autoload :Dispatch,  'solargraph/language_server/host/dispatch'

      include UriHelpers
      include Logging
      include Dispatch
      include Observable

      def initialize
        @cancel_semaphore = Mutex.new
        @buffer_semaphore = Mutex.new
        @register_semaphore = Mutex.new
        @cancel = []
        @buffer = ''
        @stopped = true
        @next_request_id = 0
        @dynamic_capabilities = Set.new
        @registered_capabilities = Set.new
      end

      # Start asynchronous process handling.
      #
      # @return [void]
      def start
        return unless stopped?
        @stopped = false
        diagnoser.start
        cataloger.start
        sources.start
      end

      # Update the configuration options with the provided hash.
      #
      # @param update [Hash]
      # @return [void]
      def configure update
        return if update.nil?
        options.merge! update
        logger.level = LOG_LEVELS[options['logLevel']] || DEFAULT_LOG_LEVEL
      end

      # @return [Hash]
      def options
        @options ||= default_configuration
      end

      # Cancel the method with the specified ID.
      #
      # @param id [Integer]
      # @return [void]
      def cancel id
        @cancel_semaphore.synchronize { @cancel.push id }
      end

      # True if the host received a request to cancel the method with the
      # specified ID.
      #
      # @param id [Integer]
      # @return [Boolean]
      def cancel? id
        result = false
        @cancel_semaphore.synchronize { result = @cancel.include? id }
        result
      end

      # Delete the specified ID from the list of cancelled IDs if it exists.
      #
      # @param id [Integer]
      # @return [void]
      def clear id
        @cancel_semaphore.synchronize { @cancel.delete id }
      end

      # Start processing a request from the client. After the message is
      # processed, the transport is responsible for sending the response.
      #
      # @param request [Hash] The contents of the message.
      # @return [Solargraph::LanguageServer::Message::Base] The message handler.
      def receive request
        if request['method']
          logger.info "Server received #{request['method']}"
          logger.debug request
          message = Message.select(request['method']).new(self, request)
          begin
            message.process
          rescue Exception => e
            logger.warn "Error processing request: [#{e.class}] #{e.message}"
            logger.warn e.backtrace.join("\n")
            message.set_error Solargraph::LanguageServer::ErrorCodes::INTERNAL_ERROR, "[#{e.class}] #{e.message}"
          end
          message
        elsif request['id']
          # @todo What if the id is invalid?
          requests[request['id']].process(request['result'])
          requests.delete request['id']
        else
          logger.warn "Invalid message received."
          logger.debug request
        end
      end

      # Respond to a notification that a file was created in the workspace.
      # The libraries will determine whether the file should be merged; see
      # Solargraph::Library#create_from_disk.
      #
      # @param uri [String] The file uri.
      # @return [Boolean] True if a library accepted the file.
      def create uri
        filename = uri_to_file(uri)
        result = false
        libraries.each do |lib|
          result = true if lib.create_from_disk(filename)
        end
        diagnoser.schedule uri if open?(uri)
        result
      end

      # Delete the specified file from the library.
      #
      # @param uri [String] The file uri.
      # @return [void]
      def delete uri
        filename = uri_to_file(uri)
        libraries.each do |lib|
          lib.delete(filename)
        end
        send_notification "textDocument/publishDiagnostics", {
          uri: uri,
          diagnostics: []
        }
      end

      # Open the specified file in the library.
      #
      # @param uri [String] The file uri.
      # @param text [String] The contents of the file.
      # @param version [Integer] A version number.
      # @return [void]
      def open uri, text, version
        src = sources.open(uri, text, version)
        libraries.each do |lib|
          lib.merge src
        end
        diagnoser.schedule uri
      end

      # @param uri [String]
      # @return [void]
      def open_from_disk uri
        library = library_for(uri)
        library.open_from_disk uri_to_file(uri)
        diagnoser.schedule uri
      end

      # True if the specified file is currently open in the library.
      #
      # @param uri [String]
      # @return [Boolean]
      def open? uri
        sources.include? uri
      end

      # Close the file specified by the URI.
      #
      # @param uri [String]
      # @return [void]
      def close uri
        logger.info "Closing #{uri}"
        sources.close uri
        diagnoser.schedule uri
      end

      # @param uri [String]
      # @return [void]
      def diagnose uri
        if sources.include?(uri)
          library = library_for(uri)
          if library.synchronized?
            logger.info "Diagnosing #{uri}"
            begin
              results = library.diagnose uri_to_file(uri)
              send_notification "textDocument/publishDiagnostics", {
                uri: uri,
                diagnostics: results
              }
            rescue DiagnosticsError => e
              logger.warn "Error in diagnostics: #{e.message}"
              options['diagnostics'] = false
              send_notification 'window/showMessage', {
                type: LanguageServer::MessageTypes::ERROR,
                message: "Error in diagnostics: #{e.message}"
              }
            end
          else
            logger.info "Deferring diagnosis of #{uri}"
            diagnoser.schedule uri
          end
        else
          send_notification 'textDocument/publishDiagnostics', {
            uri: uri,
            diagnostics: []
          }
        end
      end

      # Update a document from the parameters of a textDocument/didChange
      # method.
      #
      # @param params [Hash]
      # @return [void]
      def change params
        updater = generate_updater(params)
        sources.async_update params['textDocument']['uri'], updater
      end

      # Queue a message to be sent to the client.
      #
      # @param message [String] The message to send.
      # @return [void]
      def queue message
        @buffer_semaphore.synchronize { @buffer += message }
        changed
        notify_observers
      end

      # Clear the message buffer and return the most recent data.
      #
      # @return [String] The most recent data or an empty string.
      def flush
        tmp = nil
        @buffer_semaphore.synchronize do
          tmp = @buffer.clone
          @buffer.clear
        end
        tmp
      end

      # Prepare a library for the specified directory.
      #
      # @param directory [String]
      # @param name [String, nil]
      # @return [void]
      def prepare directory, name = nil
        # No need to create a library without a directory. The generic library
        # will handle it.
        return if directory.nil?
        logger.info "Preparing library for #{directory}"
        path = ''
        path = normalize_separators(directory) unless directory.nil?
        begin
          lib = Solargraph::Library.load(path, name)
          libraries.push lib
        rescue WorkspaceTooLargeError => e
          send_notification 'window/showMessage', {
            'type' => Solargraph::LanguageServer::MessageTypes::WARNING,
            'message' => e.message
          }
        end
      end

      # Prepare multiple folders.
      #
      # @param array [Array<Hash{String => String}>]
      # @return [void]
      def prepare_folders array
        return if array.nil?
        array.each do |folder|
          prepare uri_to_file(folder['uri']), folder['name']
        end
      end

      # Remove a directory.
      #
      # @param directory [String]
      # @return [void]
      def remove directory
        logger.info "Removing library for #{directory}"
        # @param lib [Library]
        libraries.delete_if do |lib|
          next false if lib.workspace.directory != directory
          true
        end
      end

      # @param array [Array<Hash>]
      # @return [void]
      def remove_folders array
        array.each do |folder|
          remove uri_to_file(folder['uri'])
        end
      end

      # @return [Array<String>]
      def folders
        libraries.map { |lib| lib.workspace.directory }
      end

      # Send a notification to the client.
      #
      # @param method [String] The message method
      # @param params [Hash] The method parameters
      # @return [void]
      def send_notification method, params
        response = {
          jsonrpc: "2.0",
          method: method,
          params: params
        }
        json = response.to_json
        envelope = "Content-Length: #{json.bytesize}\r\n\r\n#{json}"
        queue envelope
        logger.info "Server sent #{method}"
        logger.debug params
      end

      # Send a request to the client and execute the provided block to process
      # the response. If an ID is not provided, the host will use an auto-
      # incrementing integer.
      #
      # @param method [String] The message method
      # @param params [Hash] The method parameters
      # @param block [Proc] The block that processes the response
      # @yieldparam [Hash] The result sent by the client
      # @return [void]
      def send_request method, params, &block
        message = {
          jsonrpc: "2.0",
          method: method,
          params: params,
          id: @next_request_id
        }
        json = message.to_json
        requests[@next_request_id] = Request.new(@next_request_id, &block)
        envelope = "Content-Length: #{json.bytesize}\r\n\r\n#{json}"
        queue envelope
        @next_request_id += 1
        logger.info "Server sent #{method}"
        logger.debug params
      end

      # Register the methods as capabilities with the client.
      # This method will avoid duplicating registrations and ignore methods
      # that were not flagged for dynamic registration by the client.
      #
      # @param methods [Array<String>] The methods to register
      # @return [void]
      def register_capabilities methods
        logger.debug "Registering capabilities: #{methods}"
        @register_semaphore.synchronize do
          send_request 'client/registerCapability', {
            registrations: methods.select{|m| can_register?(m) and !registered?(m)}.map { |m|
              @registered_capabilities.add m
              {
                id: m,
                method: m,
                registerOptions: dynamic_capability_options[m]
              }
            }
          }
        end
      end

      # Unregister the methods with the client.
      # This method will avoid duplicating unregistrations and ignore methods
      # that were not flagged for dynamic registration by the client.
      #
      # @param methods [Array<String>] The methods to unregister
      # @return [void]
      def unregister_capabilities methods
        logger.debug "Unregistering capabilities: #{methods}"
        @register_semaphore.synchronize do
          send_request 'client/unregisterCapability', {
            unregisterations: methods.select{|m| registered?(m)}.map{ |m|
              @registered_capabilities.delete m
              {
                id: m,
                method: m
              }
            }
          }
        end
      end

      # Flag a method as available for dynamic registration.
      #
      # @param method [String] The method name, e.g., 'textDocument/completion'
      # @return [void]
      def allow_registration method
        @register_semaphore.synchronize do
          @dynamic_capabilities.add method
        end
      end

      # True if the specified LSP method can be dynamically registered.
      #
      # @param method [String]
      # @return [Boolean]
      def can_register? method
        @dynamic_capabilities.include?(method)
      end

      # True if the specified method has been registered.
      #
      # @param method [String] The method name, e.g., 'textDocument/completion'
      # @return [Boolean]
      def registered? method
        @registered_capabilities.include?(method)
      end

      def synchronizing?
        !libraries.all?(&:synchronized?)
      end

      # @return [void]
      def stop
        return if @stopped
        @stopped = true
        cataloger.stop
        diagnoser.stop
        sources.stop
        changed
        notify_observers
      end

      def stopped?
        @stopped
      end

      # Locate multiple pins that match a completion item. The first match is
      # based on the corresponding location in a library source if available.
      # Subsequent matches are based on path.
      #
      # @param params [Hash] A hash representation of a completion item
      # @return [Array<Pin::Base>]
      def locate_pins params
        return [] unless params['data'] && params['data']['uri']
        library = library_for(params['data']['uri'])
        result = []
        if params['data']['location']
          location = Location.new(
            params['data']['location']['filename'],
            Range.from_to(
              params['data']['location']['range']['start']['line'],
              params['data']['location']['range']['start']['character'],
              params['data']['location']['range']['end']['line'],
              params['data']['location']['range']['end']['character']
            )
          )
          result.concat library.locate_pins(location).select{ |pin| pin.name == params['label'] }
        end
        if params['data']['path']
          result.concat library.path_pins(params['data']['path'])
        end
        result.uniq
      end

      # @param uri [String]
      # @return [String]
      def read_text uri
        library = library_for(uri)
        filename = uri_to_file(uri)
        library.read_text(filename)
      end

      # @param uri [String]
      # @param line [Integer]
      # @param column [Integer]
      # @return [Solargraph::SourceMap::Completion]
      def completions_at uri, line, column
        library = library_for(uri)
        library.completions_at uri_to_file(uri), line, column
      end

      # @param uri [String]
      # @param line [Integer]
      # @param column [Integer]
      # @return [Array<Solargraph::Pin::Base>]
      def definitions_at uri, line, column
        library = library_for(uri)
        library.definitions_at(uri_to_file(uri), line, column)
      end

      # @param uri [String]
      # @param line [Integer]
      # @param column [Integer]
      # @return [Array<Solargraph::Pin::Base>]
      def signatures_at uri, line, column
        library = library_for(uri)
        library.signatures_at(uri_to_file(uri), line, column)
      end

      # @param uri [String]
      # @param line [Integer]
      # @param column [Integer]
      # @param strip [Boolean] Strip special characters from variable names
      # @return [Array<Solargraph::Range>]
      def references_from uri, line, column, strip: true
        library = library_for(uri)
        library.references_from(uri_to_file(uri), line, column, strip: strip)
      end

      # @param query [String]
      # @return [Array<Solargraph::Pin::Base>]
      def query_symbols query
        result = []
        (libraries + [generic_library]).each { |lib| result.concat lib.query_symbols(query) }
        result.uniq
      end

      # @param query [String]
      # @return [Array<String>]
      def search query
        result = []
        libraries.each { |lib| result.concat lib.search(query) }
        result
      end

      # @param query [String]
      # @return [String]
      def document query
        result = []
        libraries.each { |lib| result.concat lib.document(query) }
        result
      end

      # @param uri [String]
      # @return [Array<Solargraph::Pin::Base>]
      def document_symbols uri
        library = library_for(uri)
        # At this level, document symbols should be unique; e.g., a
        # module_function method should return the location for Module.method
        # or Module#method, but not both.
        library.document_symbols(uri_to_file(uri)).uniq(&:location)
      end

      # Send a notification to the client.
      #
      # @param text [String]
      # @param type [Integer] A MessageType constant
      # @return [void]
      def show_message text, type = LanguageServer::MessageTypes::INFO
        send_notification 'window/showMessage', {
          type: type,
          message: text
        }
      end

      # Send a notification with optional responses.
      #
      # @param text [String]
      # @param type [Integer] A MessageType constant
      # @param actions [Array<String>] Response options for the client
      # @param block The block that processes the response
      # @yieldparam [String] The action received from the client
      # @return [void]
      def show_message_request text, type, actions, &block
        send_request 'window/showMessageRequest', {
          type: type,
          message: text,
          actions: actions
        }, &block
      end

      # Get a list of IDs for server requests that are waiting for responses
      # from the client.
      #
      # @return [Array<Integer>]
      def pending_requests
        requests.keys
      end

      # @return [Hash{String => Object}]
      def default_configuration
        {
          'completion' => true,
          'hover' => true,
          'symbols' => true,
          'definitions' => true,
          'rename' => true,
          'references' => true,
          'autoformat' => false,
          'diagnostics' => false,
          'formatting' => false,
          'folding' => true,
          'logLevel' => 'warn'
        }
      end

      # @param uri [String]
      # @return [Array<Range>]
      def folding_ranges uri
        sources.find(uri).folding_ranges
      end

      # @return [void]
      def catalog
        libraries.each(&:catalog)
      end

      private

      # @return [Diagnoser]
      def diagnoser
        @diagnoser ||= Diagnoser.new(self)
      end

      # @return [Cataloger]
      def cataloger
        @cataloger ||= Cataloger.new(self)
      end

      # A hash of client requests by ID. The host uses this to keep track of
      # pending responses.
      #
      # @return [Hash{Integer => Hash}]
      def requests
        @requests ||= {}
      end

      def normalize_separators path
        return path if File::ALT_SEPARATOR.nil?
        path.gsub(File::ALT_SEPARATOR, File::SEPARATOR)
      end

      def generate_updater params
        changes = []
        params['contentChanges'].each do |chng|
          changes.push Solargraph::Source::Change.new(
            (chng['range'].nil? ? 
              nil :
              Solargraph::Range.from_to(chng['range']['start']['line'], chng['range']['start']['character'], chng['range']['end']['line'], chng['range']['end']['character'])
            ),
            chng['text']
          )
        end
        Solargraph::Source::Updater.new(
          uri_to_file(params['textDocument']['uri']),
          params['textDocument']['version'],
          changes
        )
      end

      # @return [Hash]
      def dynamic_capability_options
        @dynamic_capability_options ||= {
          # textDocumentSync: 2, # @todo What should this be?
          'textDocument/completion' => {
            resolveProvider: true,
            triggerCharacters: ['.', ':', '@']
          },
          # hoverProvider: true,
          # definitionProvider: true,
          'textDocument/signatureHelp' => {
            triggerCharacters: ['(', ',', ' ']
          },
          # documentFormattingProvider: true,
          'textDocument/onTypeFormatting' => {
            firstTriggerCharacter: '{',
            moreTriggerCharacter: ['(']
          },
          # documentSymbolProvider: true,
          # workspaceSymbolProvider: true,
          # workspace: {
            # workspaceFolders: {
              # supported: true,
              # changeNotifications: true
            # }
          # }
          'textDocument/definition' => {
            definitionProvider: true
          },
          'textDocument/references' => {
            referencesProvider: true
          },
          'textDocument/rename' => {
            renameProvider: {prepareProvider: true}
          },
          'textDocument/documentSymbol' => {
            documentSymbolProvider: true
          },
          'workspace/symbol' => {
            workspaceSymbolProvider: true
          },
          'textDocument/formatting' => {
            formattingProvider: true
          },
          'textDocument/foldingRange' => {
            foldingRangeProvider: true
          }
        }
      end
    end
  end
end
