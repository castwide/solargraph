require 'backport'

module Solargraph
  module LanguageServer
    module Transport
      # A common module for running language servers in Backport.
      #
      module Adapter
        def opening
          @host = Solargraph::LanguageServer::Host.new
          @host.add_observer self
          @host.start
          @data_reader = Solargraph::LanguageServer::Transport::DataReader.new
          @data_reader.set_message_handler do |message|
            process message
          end
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

        def update
          if @host.stopped?
            shutdown
          else
            tmp = @host.flush
            write tmp unless tmp.empty?
          end
        end

        private

        # @param request [String]
        # @return [void]
        def process request
          message = @host.receive(request)
          message.send_response
          # tmp = @host.flush
          # write tmp unless tmp.empty?
        end

        def shutdown
          Backport.stop unless @host.options['transport'] == 'external'
        end
      end
    end
  end
end
