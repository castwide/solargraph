require 'backport'

module Solargraph
  module LanguageServer
    module Transport
      # A common module for running language servers in Backport.
      #
      module Adapter
        @@timer_is_running = false

        def opening
          @host = Solargraph::LanguageServer::Host.new
          @host.add_observer self, :update
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
        def sending data
          @data_reader.receive data
        end

        def update subject
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
          tmp = @host.flush
          write tmp unless tmp.empty?
        end

        def shutdown
          Backport.stop unless @host.options['transport'] == 'external'
        end
      end
    end
  end
end
