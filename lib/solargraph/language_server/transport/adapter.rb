require 'backport'

module Solargraph
  module LanguageServer
    module Transport
      # A common module for running language servers in Backport.
      #
      module Adapter
        def opening
          @host = Solargraph::LanguageServer::Host.new
          @host.start
          @data_reader = Solargraph::LanguageServer::Transport::DataReader.new
          @data_reader.set_message_handler do |message|
            process message
          end
          start_timer
        end

        def closing
          @host.stop
        end

        # @param data [String]
        def receiving data
          @data_reader.receive data
        end
        # @todo Temporary alias to avoid problems due to a breaking change in
        #   the Backport API
        alias sending receiving

        private

        # @param request [String]
        # @return [void]
        def process request
          message = @host.receive(request)
          message.send_response
          tmp = @host.flush
          write tmp unless tmp.empty?
        end

        def start_timer
          Backport.prepare_interval 0.1 do |server|
            if @host.stopped?
              server.stop
              shutdown
            else
              tmp = @host.flush
              write tmp unless tmp.empty?
            end
          end
        end

        def shutdown
          Backport.stop unless @host.options['transport'] == 'external'
        end
      end
    end
  end
end
