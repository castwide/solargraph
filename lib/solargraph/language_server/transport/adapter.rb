module Solargraph
  module LanguageServer
    module Transport
      # A common module for running language servers in Backport.
      #
      module Adapter
        @@timer_is_running = false

        def opening
          @host = Solargraph::LanguageServer::Host.new
          @host.start
          @data_reader = Solargraph::LanguageServer::Transport::DataReader.new
          @data_reader.set_message_handler do |message|
            process message
          end
        end

        def closing
          @host.stop
          Backport.stop unless @host.options['transport'] == 'external'
        end

        # @param data [String]
        def sending data
          @data_reader.receive data
        end

        private

        # @param request [String]
        # @return [void]
        def process request
          message = @host.receive(request)
          Solargraph::Logging.logger.info "Sending response to #{request['method']}"
          message.send_response
          tmp = @host.flush
          write tmp unless tmp.empty?
        end
      end
    end
  end
end
