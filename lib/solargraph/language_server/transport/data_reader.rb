module Solargraph
  module LanguageServer
    module Transport
      class DataReader
        def initialize
          @in_header = true
          @content_length = 0
          @buffer = ''
        end

        def set_message_handler &block
          @message_handler = block
        end

        # @param data [String]
        def receive data
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
                  msg = JSON.parse(@buffer)
                  @message_handler.call msg unless @message_handler.nil?
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
      end
    end
  end
end
