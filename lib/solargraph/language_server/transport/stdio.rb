require 'thread'

module Solargraph
  module LanguageServer
    module Transport
      class Stdio
        def initialize
          # binmode is necessary to avoid EOL conversions
          STDOUT.binmode
          @host = Solargraph::LanguageServer::Host.new
          @data_reader = Solargraph::LanguageServer::Transport::DataReader.new
          @data_reader.set_message_handler do |message|
            process message
          end
        end

        def run
          start_reader
          start_timers
        end

        def self.run
          std = Stdio.new
          std.run
          std
        end

        private

        def start_reader
          Thread.new do
            until @host.stopped?
              char = STDIN.sysread(1)
              break if char.nil?
              @data_reader.receive char
              STDIN.flush
            end
          end
        end

        def send_data message
          STDOUT.write message
          STDOUT.flush
        end

        def process request
          message = @host.start(request)
          message.send_response
          tmp = @host.flush
          send_data tmp unless tmp.empty?
        end

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
