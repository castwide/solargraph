module Solargraph
  module LanguageServer
    module Transport
      # A module for running language servers over STDIO in Backport.
      #
      module Stdio
        def opening
          @host = Solargraph::LanguageServer::Host.new
          @data_reader = Solargraph::LanguageServer::Transport::DataReader.new
          @data_reader.set_message_handler do |message|
            process message
          end
          start_timers
        end

        def process request
          message = @host.start(request)
          message.send_response
          tmp = @host.flush
          write tmp unless tmp.empty?
        end

        # @param data [String]
        def sending data
          @data_reader.receive data
        end

        private

        def start_timers
          Backport.prepare_interval 0.1 do
            tmp = @host.flush
            write tmp unless tmp.empty?
            if @host.stopped?
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
end
