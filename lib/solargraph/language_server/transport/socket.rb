module Solargraph
  module LanguageServer
    module Transport
      module Socket
        def post_init
          @in_header = true
          @content_length = 0
          @buffer = ''
          @host = Solargraph::LanguageServer::Host.new
        end
      
        def process request
          Thread.new {
            begin
              message = @host.start(request)
              message.send
              send_data @host.flush
            rescue Exception => e
              # @todo Send error message
              STDERR.puts "#{e}"
              STDERR.puts "#{e.backtrace}"
            end
          }
        end
      
        # @param data [String]
        def receive_data data
          data.each_byte do |char|
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
                process JSON.parse(@buffer)
                @buffer.clear
                @in_header = true
                @content_length = 0
              end
            end
          end
        end      
      end
    end
  end
end
