# require 'rubocop'
require 'thread'
require 'set'

module Solargraph
  module LanguageServer
    # The language server protocol's data provider. Hosts are responsible for
    # querying the library and processing messages.
    #
    class Host
      include Solargraph::LanguageServer::UriHelpers

      # @return [Solargraph::Library]
      attr_reader :library

      def initialize
        @change_semaphore = Mutex.new
        @buffer_semaphore = Mutex.new
        @change_queue = []
        @diagnostics_queue = []
        @cancel = []
        @buffer = ''
        @stopped = false
        @library = nil # @todo How to initialize the library
        start_change_thread
        start_diagnostics_thread
      end

      # @param update [Hash]
      def configure update
        options.merge! update
      end

      # @return [Hash]
      def options
        @options ||= {}
      end

      def cancel id
        @cancel.push id
      end

      def cancel? id
        @cancel.include? id
      end

      def clear id
        @cancel.delete id
      end

      def start request
        message = Message.select(request['method']).new(self, request)
        begin
          message.process
        rescue Exception => e
          STDERR.puts e.message
          STDERR.puts e.backtrace
          message.set_error Solargraph::LanguageServer::ErrorCodes::INTERNAL_ERROR, e.message
        end
        message
      end

      def create uri
        filename = uri_to_file(uri)
        library.create filename, File.read(filename)
      end

      def delete uri
        filename = uri_to_file(uri)
        library.delete filename
      end

      def open uri, text, version
        library.open uri_to_file(uri), text, version
        @change_semaphore.synchronize { @diagnostics_queue.push uri }
      end

      def change params
        @change_semaphore.synchronize do
          if changing? params['textDocument']['uri']
            @change_queue.push params
          else
            source = library.checkout(uri_to_file(params['textDocument']['uri']))
            @change_queue.push params
            if params['textDocument']['version'] == source.version + params['contentChanges'].length
              source.synchronize(params['contentChanges'], params['textDocument']['version'])
              library.refresh
              @change_queue.pop
              @diagnostics_queue.push params['textDocument']['uri']
            end
          end
        end
      end

      def queue message
        @buffer_semaphore.synchronize do
          @buffer += message
        end
      end

      def flush
        tmp = nil
        @buffer_semaphore.synchronize do
          tmp = @buffer.clone
          @buffer.clear
        end
        tmp
      end

      # @param directory [String]
      def prepare directory
        path = nil
        path = normalize_separators(directory) unless directory.nil?
        @change_semaphore.synchronize do
          @library = Solargraph::Library.load(path)
        end
      end

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

      def changing? file_uri
        @change_queue.any?{|change| change['textDocument']['uri'] == file_uri}
      end

      def stop
        @stopped = true
      end

      def stopped?
        @stopped
      end

      def synchronize &block
        @change_semaphore.synchronize do
          block.call
        end
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
        library.read_text(filename)
      end

      def completions_at filename, line, column
        results = nil
        @change_semaphore.synchronize do
          results = library.completions_at filename, line, column
        end
        results
      end

      # @return [Array<Solargraph::Pin::Base>]
      def definitions_at filename, line, column
        results = nil
        @change_semaphore.synchronize do
          results = library.definitions_at filename, line, column
        end
        results
      end

      private

      def start_change_thread
        Thread.new do
          until stopped?
            @change_semaphore.synchronize do
              begin
                changed = false
                @change_queue.delete_if do |change|
                  filename = uri_to_file(change['textDocument']['uri'])
                  source = library.checkout(filename)
                  if change['textDocument']['version'] == source.version + change['contentChanges'].length
                    source.synchronize(change['contentChanges'], change['textDocument']['version'])
                    @diagnostics_queue.push change['textDocument']['uri']
                    changed = true
                    true
                  elsif change['textDocument']['version'] == source.version + 1 #and change['contentChanges'].length == 0
                    # HACK: This condition fixes the fact that formatting
                    # increments the version by one regardless of the number
                    # of changes
                    source.synchronize(change['contentChanges'], change['textDocument']['version'])
                    @diagnostics_queue.push change['textDocument']['uri']
                    true
                  elsif change['textDocument']['version'] <= source.version
                    # @todo Is deleting outdated changes correct behavior?
                    STDERR.puts "Deleting stale change"
                    @diagnostics_queue.push change['textDocument']['uri']
                    changed = true
                    true
                  else
                    # @todo Change is out of order. Save it for later
                    STDERR.puts "Kept in queue: #{change['textDocument']['uri']} from #{source.version} to #{change['textDocument']['version']}"
                    false
                  end
                end
                STDERR.puts "#{@change_queue.length} pending" unless @change_queue.empty?
                library.refresh if changed
              rescue Exception => e
                STDERR.puts e.message
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
            if options['diagnostics'] != 'rubocop'
              @change_semaphore.synchronize { @diagnostics_queue.clear }
              sleep 1
              next
            end
            unless @change_semaphore.locked?
              begin
                current = nil
                @change_semaphore.synchronize do
                  current = @diagnostics_queue.shift
                end
                unless current.nil?
                  already_changing = false
                  @change_semaphore.synchronize { already_changing = (changing?(current) or @diagnostics_queue.include?(current)) }
                  unless already_changing
                    filename = nil
                    text = nil
                    @change_semaphore.synchronize do
                      filename = uri_to_file(current)
                      text = library.read_text(filename)
                    end
                    results = diagnoser.diagnose text, filename
                    @change_semaphore.synchronize { already_changing = (changing?(current) or @diagnostics_queue.include?(current)) }
                    # publish_diagnostics current, resp unless already_changing
                    unless already_changing
                      send_notification "textDocument/publishDiagnostics", {
                        uri: current,
                        diagnostics: results
                      }
                    end
                  end
                end
              rescue Exception => e
                STDERR.puts e.message
              end
            end
            sleep 0.1
          end
        end
      end

      def normalize_separators path
        return path if File::ALT_SEPARATOR.nil?
        path.gsub(File::ALT_SEPARATOR, File::SEPARATOR)
      end
    end
  end
end
