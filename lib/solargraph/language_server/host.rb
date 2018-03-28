require 'thread'
require 'set'

module Solargraph
  module LanguageServer
    # The base language server data provider.
    #
    class Host
      include Solargraph::LanguageServer::UriHelpers

      # attr_reader :workspace
      attr_reader :library

      def initialize
        # @type [Hash<String, Solargraph::Source]
        # @file_source = {}
        @change_semaphore = Mutex.new
        @buffer_semaphore = Mutex.new
        @change_queue = []
        @cancel = []
        @buffer = ''
        @stopped = false
        @library = nil # @todo How to initialize the library
        start_change_thread
      end

      # @param options [Hash]
      def configure options
        @options = options
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
        path = normalize_separators(directory)
        @library = Solargraph::Library.load(path)
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
        EventMachine.stop
        exit
      end

      def stopped?
        @stopped
      end

      def synchronize &block
        @change_semaphore.synchronize do
          block.call
        end
      end

      private

      def start_change_thread
        Thread.new do
          until stopped?
            changed = false
            @change_semaphore.synchronize do
              @change_queue.delete_if do |change|
                filename = uri_to_file(change['textDocument']['uri'])
                source = read(change['textDocument']['uri'])
                if change['textDocument']['version'] == source.version + change['contentChanges'].length
                  source.synchronize(change['contentChanges'], change['textDocument']['version'])
                  changed = true
                  true
                elsif change['textDocument']['version'] <= source.version
                  # @todo Is deleting outdated changes correct behavior?
                  changed = true
                  true
                else
                  # @todo Change is out of order. Save it for later
                  false
                end
              end
              library.refresh if changed
            end
            sleep 1
          end
        end
      end

      def normalize_separators path
        path.gsub(File::ALT_SEPARATOR, File::SEPARATOR)
      end

      def version_hash
        @version_hash ||= {}
      end
    end
  end
end
