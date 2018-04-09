require 'thread'

module Solargraph
  module LanguageServer
    module Transport
      # A module for running language servers in EventMachine.
      #
      module Socket
        def post_init
          @in_header = true
          @content_length = 0
          @buffer = ''
          @host = Solargraph::LanguageServer::Host.new
          @stack = {}
          @semaphore = Mutex.new
          start_timers
        end

        def process request
          Thread.new do
            @semaphore.synchronize {
              @stack[request['id']] = request['method']
            }
            message = @host.start(request)
            message.send
            tmp = @host.flush
            send_data tmp unless tmp.empty?
            GC.start unless request['method'] == 'textDocument/didChange'
            @semaphore.synchronize {
              @stack.delete request['id']
            }
          end
        end

        # @param data [String]
        def receive_data data
          data.each_char do |char|
            @buffer.concat char
            if @in_header
              if @buffer.end_with?("\r\n\r\n")
                @in_header = false
                @buffer.each_line do |line|
                  parts = line.split(':').map(&:strip)
                  if parts[0] == 'Content-Length'
                    @content_length = parts[1].to_i
                    break
                  end
                end
                @buffer.clear
              end
            else
              if @buffer.bytesize == @content_length
                begin
                  process JSON.parse(@buffer)
                rescue JSON::ParserError => e
                  STDERR.puts "Failed to parse request: #{e.message}"
                  STDERR.puts "Buffer: #{@buffer}"
                ensure
                  @buffer.clear
                  @in_header = true
                  @content_length = 0
                end
              end
            end
          end
        end

        private

        def start_timers
          EventMachine.add_periodic_timer 0.1 do
            tmp = @host.flush
            send_data tmp unless tmp.empty?
            EventMachine.stop if @host.stopped?
          end

          EventMachine.add_periodic_timer 10 do
            @semaphore.synchronize {
              STDERR.puts @stack.inspect
            }
          end
        end
      end
    end
  end
end
