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
        @source_semaphore = Mutex.new
        @buffer_semaphore = Mutex.new
        @change_semaphore = Mutex.new
        @changers = []
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
        source = nil
        @source_semaphore.synchronize {
          source = @file_source[filename]
        }
        source
      end

      def open filename, text
        #change filename, text
        @source_semaphore.synchronize {
          @file_source[filename] = Solargraph::ApiMap::Source.fix(text, filename)
        }
      end

      def change filename, changes
        sleep 0.01 while @changers.include?(filename)
        @change_semaphore.synchronize {
          @changers.push filename
        }
        @source_semaphore.synchronize {
          src = @file_source[filename]
          if src.nil?
            STDERR.puts "NOOOOO!!!!!!!!!!! Trying to change a file that's not open?"
          else
            #@file_source[filename] = src.synchronize(changes)
            src.synchronize changes
          end
        }
        @change_semaphore.synchronize {
          @changers.slice!(@changers.index(filename))
        }
      end

      def reload_sources
        @source_semaphore.synchronize {
          @file_source.each_pair do |name, source|
            next if @changers.include?(name)
            @file_source[name]= Solargraph::ApiMap::Source.fix(source.code, name) if source.stale?
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
