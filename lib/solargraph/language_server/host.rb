require 'thread'
require 'set'

module Solargraph
  module LanguageServer
    # The base language server data provider.
    #
    class Host
      attr_accessor :resolvable

      attr_reader :workspace

      def initialize
        # @type [Hash<String, Solargraph::Source]
        @file_source = {}
        @change_semaphore = Mutex.new
        @buffer_semaphore = Mutex.new
        @change_queue = []
        @cancel = []
        @buffer = ''
        @stopped = false
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
        message.process
        message
      end

      def read uri
        source = nil
        @change_semaphore.synchronize {
          source = @file_source[uri]
        }
        source
      end

      def open text_document
        @change_semaphore.synchronize do
          text = text_document['text'] || File.read(uri_to_file(text_document['uri']))
          @file_source[text_document['uri']] = Solargraph::Source.fix(text, uri_to_file(text_document['uri']))
          @file_source[text_document['uri']].version = text_document['version']
          @change_queue.delete_if { |c| c['textDocument']['uri'] == text_document['uri'] and c['textDocument']['version'] < @file_source[text_document['uri']].version }
        end
      end

      def change params
        @change_semaphore.synchronize {
          filename = uri_to_file(params['textDocument']['uri'])
          source = @file_source[params['textDocument']['uri']]
          if params['textDocument']['version'] == source.version || params['textDocument']['version'] == source.version + 1
            source.synchronize(params['contentChanges'], params['textDocument']['version'])
          else
            @change_queue.push params
          end
        }
      end

      def close filename
        @source_semaphore.synchronize { @file_source.delete filename }
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
        @workspace = Workspace.new(directory)
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
        result = false
        @change_semaphore.synchronize {
          result = @change_queue.any?{|change| change['textDocument']['uri'] == file_uri}
        }
        result
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
            @change_semaphore.synchronize do
              @change_queue.sort!{|a, b| a.version <=> b.version}
              @change_queue.delete_if do |change|
                filename = uri_to_file(change['textDocument']['uri'])
                source = @file_source[change['textDocument']['uri']]
                # @todo What if source is nil?
                if change['textDocument']['version'] == source.version || change['textDocument']['version'] == source.version + 1
                  source.synchronize(change['contentChanges'], change['textDocument']['version'])
                  true
                elsif change['textDocument']['version'] < source.version
                  true
                else
                  false
                end
              end
            end
            sleep 0.001
          end
        end
      end

      def uri_to_file uri
        URI.decode(uri.gsub(/^file\:\/\//, '').gsub(/^\/([a-z]:)/i, '\1'))
      end
    end
  end
end
