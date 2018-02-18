require 'thread'
require 'set'

module Solargraph
  module LanguageServer
    # The base language server data provider.
    #
    class Host
      attr_accessor :resolvable
      attr_reader :api_map
  
      def initialize
        @api_map = Solargraph::ApiMap.new
        # @type [Hash<String, Solargraph::ApiMap::Source]
        @file_source = {}
        @semaphore = Mutex.new
        @buffer_semaphore = Mutex.new
        @cancel = []
        @buffer = ''
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

      def read filename
        #text = nil
        #@semaphore.synchronize { text = @files[filename] }
        #text
        source = nil
        @semaphore.synchronize {
          source = @file_source[filename]
        }
        source
      end

      def open filename, text
        #change filename, text
        @semaphore.synchronize {
          STDERR.puts "Opening a damn file"
          @file_source[filename] = Solargraph::ApiMap::Source.fix(text, filename)
        }
      end

      def change filename, changes
        @semaphore.synchronize {
          STDERR.puts "Changing a damn file"
          #@files[filename] = changes[0]['text']
          src = @file_source[filename]
          if src.nil?
            STDERR.puts "NOOOOO!!!!!!!!!!! Trying to change a file that's not open?"
          else
            changes.each do |change|
              @file_source[filename] = src.synchronize(change)
            end
          end
        }
      end

      def close filename
        @semaphore.synchronize { @file_source.delete filename }
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

      def prepare workspace
        @api_map = Solargraph::ApiMap.new(workspace)
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
    end
  end
end
