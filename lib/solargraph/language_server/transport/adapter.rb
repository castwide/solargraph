module Solargraph
  module LanguageServer
    module Transport
      # A common module for running language servers in Backport.
      #
      module Adapter
        @@timer_is_running = false

        def opening
          @host = Solargraph::LanguageServer::Host.new
          @data_reader = Solargraph::LanguageServer::Transport::DataReader.new
          @data_reader.set_message_handler do |message|
            process message
          end
          start_timers
        end

        # @param data [String]
        def sending data
          @data_reader.receive data
        end

        private

        # @param request [String]
        # @return [void]
        def process request
          message = @host.start(request)
          message.send_response
          tmp = @host.flush
          write tmp unless tmp.empty?
        end

        # @return [void]
        def start_timers
          return if @@timer_is_running
          @@timer_is_running = true
          Backport.prepare_interval 0.1 do
            tmp = @host.flush
            write tmp unless tmp.empty?
            next unless @host.stopped?
            if @host.options['transport'] == 'external'
              @host = Solargraph::LanguageServer::Host.new
            else
              Backport.stop
            end
          end
        end
      end
    end
  end
end
