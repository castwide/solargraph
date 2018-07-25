require 'thread'
require 'set'

module Solargraph
  module LanguageServer
    # The language server protocol's data provider. Hosts are responsible for
    # querying the library and processing messages. They also provide thread
    # safety for multi-threaded transports.
    #
    class Host
      include Solargraph::LanguageServer::UriHelpers

      def initialize
        @change_semaphore = Mutex.new
        @cancel_semaphore = Mutex.new
        @buffer_semaphore = Mutex.new
        @register_semaphore = Mutex.new
        @initialized = false
        @change_queue = []
        @diagnostics_queue = []
        @cancel = []
        @buffer = ''
        @stopped = false
        @next_request_id = 0
        @dynamic_capabilities = Set.new
        @registered_capabilities = Set.new
        start_change_thread
        start_diagnostics_thread
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

      # Get / Set initialized property
      #
      # @param val [Boolean]
      # @return [Boolean]
      def initialized val = nil
        @initialized = val unless val.nil?
        @initialized
      end

      # Start processing a request from the client. After the message is
      # processed, the transport is responsible for sending the response.
      #
      # @param request [Hash] The contents of the message.
      # @return [Solargraph::LanguageServer::Message::Base] The message handler.
      def start request
        if request['method']
          if request['method'] == 'initialize'
            message = start_method request
            params = request['params'] || {}
            # if using files extension load files from client
            if params['capabilities']['xfilesProvider'] and params['capabilities']['xcontentProvider']
              prepare_remote params['rootPath']
            # otherwise load files locally
            else
              prepare params['rootPath']
              @initialized = true
            end
            message
          else
            # wait till initialized to process - each request is in own thread
            # so this will only block the request thread
            while !@initialized
              sleep 1
            end
            start_method request
          end
        elsif request['id']
          # @todo What if the id is invalid?
          requests[request['id']].process(request['result'])
          requests.delete request['id']
        else
          STDERR.puts "Invalid message received."
        end
      end

      def start_method request
        message = Message.select(request['method']).new(self, request)
        begin
          message.process
        rescue Exception => e
          STDERR.puts e.message
          STDERR.puts e.backtrace
          message.set_error Solargraph::LanguageServer::ErrorCodes::INTERNAL_ERROR, "[#{e.class}] #{e.message}"
        end
        message
      end

      # Respond to a notification that a file was created in the workspace.
      # The library will determine whether the file should be added to the
      # workspace; see Solargraph::Library#create_from_disk.
      #
      # @param uri [String] The file uri.
      def create uri
        filename = uri_to_file(uri)
        @change_semaphore.synchronize do
          library.create_from_disk filename
        end
      end

      # Delete the specified file from the library.
      #
      # @param uri [String] The file uri.
      def delete uri
        @change_semaphore.synchronize do
          filename = uri_to_file(uri)
          library.delete filename
          # Remove diagnostics for deleted files
          send_notification "textDocument/publishDiagnostics", {
            uri: uri,
            diagnostics: []
          }
        end
      end

      # Open the specified file in the library.
      #
      # @param uri [String] The file uri.
      # @param text [String] The contents of the file.
      # @param version [Integer] A version number.
      def open uri, text, version
        @change_semaphore.synchronize do
          library.open uri_to_file(uri), text, version
          @diagnostics_queue.push uri
        end
      end

      # True if the specified file is currently open in the library.
      #
      # @param uri [String]
      # @return [Boolean]
      def open? uri
        result = nil
        @change_semaphore.synchronize do
          result = library.open?(uri_to_file(uri))
        end
        result
      end

      # Close the file specified by the URI.
      #
      # @param uri [String]
      def close uri
        @change_semaphore.synchronize do
          library.close uri_to_file(uri)
          @diagnostics_queue.push uri
        end
      end

      def save params
        @change_semaphore.synchronize do
          uri = params['textDocument']['uri']
          filename = uri_to_file(uri)
          version = params['textDocument']['version']
          @change_queue.delete_if do |change|
            return true if change['textDocument']['uri'] == uri and change['textDocument']['version'] <= version
            false
          end
          library.overwrite filename, version
        end
      end

      def change params
        @change_semaphore.synchronize do
          if unsafe_changing? params['textDocument']['uri']
            @change_queue.push params
          else
            source = library.checkout(uri_to_file(params['textDocument']['uri']))
            @change_queue.push params
            if params['textDocument']['version'] == source.version + params['contentChanges'].length
              updater = generate_updater(params)
              library.synchronize updater
              library.refresh
              @change_queue.pop
              @diagnostics_queue.push params['textDocument']['uri']
            end
          end
        end
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
        @change_semaphore.synchronize do
          begin
            @library = Solargraph::Library.load(path)
          rescue WorkspaceTooLargeError => e
            send_notification 'window/showMessage', {
              'type' => Solargraph::LanguageServer::MessageTypes::WARNING,
              'message' => "The workspace is too large to index (#{e.size} files, max #{e.max})"
            }
            @library = Solargraph::Library.load(nil)
          end
        end
      end

      # Prepare a library for the specified directory using remote file
      # system.
      #
      # @param directory [String]
      def prepare_remote directory
        path = nil
        path = normalize_separators(directory) unless directory.nil?
        begin
          @library = Solargraph::LibraryRemote.load(self, path)
        rescue WorkspaceTooLargeError => e
          send_notification 'window/showMessage', {
            'type' => Solargraph::LanguageServer::MessageTypes::WARNING,
            'message' => "The workspace is too large to index (#{e.size} files, max #{e.max})"
          }
          @library = Solargraph::Library.load(nil)
        end
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
        result = false
        @change_semaphore.synchronize do
          result = unsafe_changing?(file_uri)
        end
        result
      end

      def stop
        @stopped = true
      end

      def stopped?
        @stopped
      end

      def locate_pin params
        pin = nil
        @change_semaphore.synchronize do
          pin = library.locate_pin(params['data']['location']) unless params['data']['location'].nil?
          # @todo Improve pin location
          if pin.nil? or pin.path != params['data']['path']
            pin = library.path_pins(params['data']['path']).first
          end
        end
        pin
      end

      def read_text uri
        filename = uri_to_file(uri)
        text = nil
        @change_semaphore.synchronize do
          text = library.read_text(filename)
        end
        text
      end

      def completions_at filename, line, column
        result = nil
        @change_semaphore.synchronize do
          result = library.completions_at filename, line, column
        end
        result
      end

      # @return [Array<Solargraph::Pin::Base>]
      def definitions_at filename, line, column
        result = []
        @change_semaphore.synchronize do
          result = library.definitions_at(filename, line, column)
        end
        result
      end

      def signatures_at filename, line, column
        result = nil
        @change_semaphore.synchronize do
          result = library.signatures_at(filename, line, column)
        end
        result
      end

      def references_from filename, line, column
        result = nil
        @change_semaphore.synchronize do
          result = library.references_from(filename, line, column)
        end
        result
      end

      def query_symbols query
        result = nil
        @change_semaphore.synchronize { result = library.query_symbols(query) }
        result
      end

      def search query
        result = nil
        @change_semaphore.synchronize { result = library.search(query) }
        result
      end

      def document query
        result = nil
        @change_semaphore.synchronize { result = library.document(query) }
        result
      end

      # @param uri [String]
      # @return [Array<Solargraph::Pin::Base>]
      def file_symbols uri
        library.file_symbols(uri_to_file(uri))
      end

      def show_message text, type = LanguageServer::MessageTypes::INFO
        send_notification 'window/showMessage', {
          type: type,
          message: text
        }
      end

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

      private

      # @return [Solargraph::Library]
      def library
        @library
      end

      def unsafe_changing? file_uri
        @change_queue.any?{|change| change['textDocument']['uri'] == file_uri}
      end

      def requests
        @requests ||= {}
      end

      def start_change_thread
        Thread.new do
          until stopped?
            @change_semaphore.synchronize do
              begin
                changed = false
                @change_queue.sort!{|a, b| a['textDocument']['version'] <=> b['textDocument']['version']}
                @change_queue.delete_if do |change|
                  filename = uri_to_file(change['textDocument']['uri'])
                  source = library.checkout(filename)
                  if change['textDocument']['version'] == source.version + change['contentChanges'].length
                    updater = generate_updater(change)
                    library.synchronize updater
                    @diagnostics_queue.push change['textDocument']['uri']
                    changed = true
                    next true
                  elsif change['textDocument']['version'] == source.version + 1 #and change['contentChanges'].length == 0
                    # HACK: This condition fixes the fact that formatting
                    # increments the version by one regardless of the number
                    # of changes
                    STDERR.puts "Warning: change applied to #{uri_to_file(change['textDocument']['uri'])} is possibly out of sync"
                    updater = generate_updater(change)
                    library.synchronize updater
                    @diagnostics_queue.push change['textDocument']['uri']
                    changed = true
                    next true
                  elsif change['textDocument']['version'] <= source.version
                    # @todo Is deleting outdated changes correct behavior?
                    STDERR.puts "Warning: outdated change to #{change['textDocument']['uri']} was ignored"
                    @diagnostics_queue.push change['textDocument']['uri']
                    next true
                  else
                    # @todo Change is out of order. Save it for later
                    next false
                  end
                end
                refreshable = changed and @change_queue.empty?
                library.refresh if refreshable
              rescue Exception => e
                # Trying to get anything out of the error except its class
                # hangs the thread for some reason
                STDERR.puts "An error occurred in the change thread: #{e.class}"
              end
            end
            sleep 0.1
          end
        end
      end

      def start_diagnostics_thread
        Thread.new do
          diagnoser = Diagnostics::Rubocop.new
          until stopped?
            sleep 0.1
            if !options['diagnostics']
              @change_semaphore.synchronize { @diagnostics_queue.clear }
              next
            end
            begin
              # Diagnosis is broken into two parts to reduce the number of
              # times it runs while a document is changing
              current = nil
              already_changing = nil
              @change_semaphore.synchronize do
                current = @diagnostics_queue.shift
                break if current.nil?
                already_changing = unsafe_changing?(current)
                @diagnostics_queue.delete current unless already_changing
              end
              next if current.nil? or already_changing
              filename = uri_to_file(current)
              results = library.diagnose(filename)
              @change_semaphore.synchronize do
                already_changing = (unsafe_changing?(current) or @diagnostics_queue.include?(current))
                unless already_changing
                  send_notification "textDocument/publishDiagnostics", {
                    uri: current,
                    diagnostics: results
                  }
                end
              end
            rescue DiagnosticsError => e
              STDERR.puts "Error in diagnostics: #{e.message}"
              options['diagnostics'] = false
              send_notification 'window/showMessage', {
                type: LanguageServer::MessageTypes::ERROR,
                message: "Error in diagnostics: #{e.message}"
              }
            rescue Exception => e
              STDERR.puts "#{e.message}"
              STDERR.puts "#{e.backtrace}"
            end
          end
        end
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
              Solargraph::Source::Range.from_to(chng['range']['start']['line'], chng['range']['start']['character'], chng['range']['end']['line'], chng['range']['end']['character'])
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
