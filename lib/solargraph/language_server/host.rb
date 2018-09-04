require 'thread'
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

      include Solargraph::LanguageServer::UriHelpers

      def initialize
        @cancel_semaphore = Mutex.new
        @buffer_semaphore = Mutex.new
        @register_semaphore = Mutex.new
        @cancel = []
        @buffer = ''
        @stopped = false
        @next_request_id = 0
        @dynamic_capabilities = Set.new
        @registered_capabilities = Set.new
      end

      # Update the configuration options with the provided hash.
      #
      # @param update [Hash]
      def configure update
        return if update.nil?
        options.merge! update
      end

      # @return [Hash]
      def options
        @options ||= default_configuration
      end

      # Cancel the method with the specified ID.
      #
      # @param id [Integer]
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
      def clear id
        @cancel_semaphore.synchronize { @cancel.delete id }
      end

      # Start processing a request from the client. After the message is
      # processed, the transport is responsible for sending the response.
      #
      # @param request [Hash] The contents of the message.
      # @return [Solargraph::LanguageServer::Message::Base] The message handler.
      def start request
        if request['method']
          message = Message.select(request['method']).new(self, request)
          begin
            message.process
          rescue Exception => e
            STDERR.puts e.message
            STDERR.puts e.backtrace
            message.set_error Solargraph::LanguageServer::ErrorCodes::INTERNAL_ERROR, "[#{e.class}] #{e.message}"
          end
          message
        elsif request['id']
          # @todo What if the id is invalid?
          requests[request['id']].process(request['result'])
          requests.delete request['id']
        else
          STDERR.puts "Invalid message received."
        end
      end

      # Respond to a notification that a file was created in the workspace.
      # The library will determine whether the file should be added to the
      # workspace; see Solargraph::Library#create_from_disk.
      #
      # @param uri [String] The file uri.
      def create uri
        filename = uri_to_file(uri)
        library.create_from_disk filename
      end

      # Delete the specified file from the library.
      #
      # @param uri [String] The file uri.
      def delete uri
        filename = uri_to_file(uri)
        library.delete filename
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
      def open uri, text, version
        f = uri_to_file(uri)
        library.open uri_to_file(f), text, version
        diagnoser.schedule uri
      end

      # True if the specified file is currently open in the library.
      #
      # @param uri [String]
      # @return [Boolean]
      def open? uri
        unsafe_open?(uri)
      end

      # Close the file specified by the URI.
      #
      # @param uri [String]
      def close uri
        library.close uri_to_file(uri)
        diagnoser.schedule uri
      end

      def save params
        uri = params['textDocument']['uri']
        filename = uri_to_file(uri)
        version = params['textDocument']['version']
        library.overwrite filename, version
      end

      def diagnose uri
        library.diagnose uri_to_file(uri)
      end

      def change params
        updater = generate_updater(params)
        library.synchronize updater
        diagnoser.schedule params['textDocument']['uri']
      end

      # Queue a message to be sent to the client.
      #
      # @param message [String] The message to send.
      def queue message
        @buffer_semaphore.synchronize do
          @buffer += message
        end
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
      def prepare directory
        path = nil
        path = normalize_separators(directory) unless directory.nil?
        begin
          @library = Solargraph::Library.load(path)
        rescue WorkspaceTooLargeError => e
          send_notification 'window/showMessage', {
            'type' => Solargraph::LanguageServer::MessageTypes::WARNING,
            'message' => "The workspace is too large to index (#{e.size} files, max #{e.max})"
          }
          @library = Solargraph::Library.load(nil)
        end
        diagnoser.start
        cataloger.start
      end

      # Send a notification to the client.
      #
      # @param method [String] The message method
      # @param params [Hash] The method parameters
      def send_notification method, params
        response = {
          jsonrpc: "2.0",
          method: method,
          params: params
        }
        json = response.to_json
        envelope = "Content-Length: #{json.bytesize}\r\n\r\n#{json}"
        queue envelope
      end

      # Send a request to the client and execute the provided block to process
      # the response. If an ID is not provided, the host will use an auto-
      # incrementing integer.
      #
      # @param method [String] The message method
      # @param params [Hash] The method parameters
      # @param id [String] An optional ID
      # @yieldparam [Hash] The result sent by the client
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
      end

      # Register the methods as capabilities with the client.
      # This method will avoid duplicating registrations and ignore methods
      # that were not flagged for dynamic registration by the client.
      #
      # @param methods [Array<String>] The methods to register
      def register_capabilities methods
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
      def unregister_capabilities methods
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
      def allow_registration method
        @register_semaphore.synchronize do
          @dynamic_capabilities.add method
        end
      end

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

      # True if the specified file is in the process of changing.
      #
      # @return [Boolean]
      def changing? file_uri
        unsafe_changing?(file_uri)
      end

      def stop
        @stopped = true
        cataloger.stop
        diagnoser.stop
      end

      def stopped?
        @stopped
      end

      def locate_pin params
        pin = nil
        pin = nil
        unless params['data']['location'].nil?
          location = Location.new(
            params['data']['location']['filename'],
            Range.from_to(
              params['data']['location']['range']['start']['line'],
              params['data']['location']['range']['start']['character'],
              params['data']['location']['range']['end']['line'],
              params['data']['location']['range']['end']['character']
            )
          )
          pin = library.locate_pin(location)
        end
        # @todo Improve pin location
        if pin.nil? or pin.path != params['data']['path']
          pin = library.path_pins(params['data']['path']).first
        end
        pin
      end

      # @param uri [String]
      # @return [String]
      def read_text uri
        filename = uri_to_file(uri)
        library.read_text(filename)
      end

      # @param filename [String]
      # @param line [Integer]
      # @param column [Integer]
      # @return [Solargraph::ApiMap::Completion]
      def completions_at filename, line, column
        result = nil
        result = library.completions_at filename, line, column
        result
      end

      # @param filename [String]
      # @param line [Integer]
      # @param column [Integer]
      # @return [Array<Solargraph::Pin::Base>]
      def definitions_at filename, line, column
        library.definitions_at(filename, line, column)
      end

      # @param filename [String]
      # @param line [Integer]
      # @param column [Integer]
      # @return [Array<Solargraph::Pin::Base>]
      def signatures_at filename, line, column
        library.signatures_at(filename, line, column)
      end

      # @param filename [String]
      # @param line [Integer]
      # @param column [Integer]
      # @return [Array<Solargraph::Range>]
      def references_from filename, line, column
        result = library.references_from(filename, line, column)
      end

      # @param query [String]
      # @return [Array<Solargraph::Pin::Base>]
      def query_symbols query
        library.query_symbols(query)
      end

      # @param query [String]
      # @return [Array<String>]
      def search query
        library.search(query)
      end

      # @param query [String]
      # @return [String]
      def document query
        library.document(query)
      end

      # @param uri [String]
      # @return [Array<Solargraph::Pin::Base>]
      def document_symbols uri
        library.document_symbols(uri_to_file(uri))
      end

      # Send a notification to the client.
      #
      # @param text [String]
      # @param type [Integer] A MessageType constant
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
      # @param &block The block that processes the response
      # @yieldparam [String] The action received from the client
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
          'formatting' => false
        }
      end

      # The current library version.
      #
      # The Host::Catalog uses this number to determine whether it needs to
      # catalog the library.
      #
      # @return [Integer]
      def libver
        library.version
      end

      # Catalog the library.
      #
      # @return [void]
      def catalog
        library.catalog
      end

      private

      # @return [Solargraph::Library]
      def library
        @library
      end

      # @return [Diagnoser]
      def diagnoser
        @diagnoser ||= Diagnoser.new(self)
      end

      # @return [Cataloger]
      def cataloger
        @cataloger ||= Cataloger.new(self)
      end

      # @param file_uri [String]
      # @return [Boolean]
      def unsafe_changing? file_uri
        file = uri_to_file(file_uri)
      end

      def unsafe_open? uri
        library.open?(uri_to_file(uri))
      end

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
            triggerCharacters: ['(', ',']
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
            renameProvider: true
          },
          'textDocument/documentSymbol' => {
            documentSymbolProvider: true
          },
          'workspace/symbol' => {
            workspaceSymbolProvider: true
          }
        }
      end
    end
  end
end
