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
          @data_reader = Solargraph::LanguageServer::Transport::DataReader.new
          @data_reader.set_message_handler do |message|
            process message
          end
          start_timers
        end

        def process request
          Thread.new do
            message = @host.start(request)
            message.send
            tmp = @host.flush
            send_data tmp unless tmp.empty?
            GC.start unless request['method'] == 'textDocument/didChange'
          end
        end

        # @param data [String]
        def receive_data data
          @data_reader.receive data
        end

        private

        def start_timers
          EventMachine.add_periodic_timer 0.1 do
            tmp = @host.flush
            send_data tmp unless tmp.empty?
            EventMachine.stop if @host.stopped?
          end
        end
      end
    end
  end
end
