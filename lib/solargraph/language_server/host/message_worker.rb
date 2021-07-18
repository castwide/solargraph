# frozen_string_literal: true

module Solargraph
  module LanguageServer
    class Host
      # A serial worker Thread to handle message.
      #
      # this make check pending message possible, and maybe cancelled to speedup process
      class MessageWorker
        # @param host [Host]
        def initialize(host)
          @host = host
          @mutex = Mutex.new
          @resource = ConditionVariable.new
          @stopped = true
        end

        # pending handle messages
        def messages
          @messages ||= []
        end

        def stopped?
          @stopped
        end
        def stop
          @stopped = true
        end

        # @param message the message should be handle. will pass back to Host#receive
        def queue(message)
          @mutex.synchronize {
            messages.push(message)
            @resource.signal
          }
        end

        def start
          return unless @stopped
          @stopped = false
          Thread.new do
            tick until stopped?
          end
        end
        def tick
          message = @mutex.synchronize {
            @resource.wait(@mutex) if messages.empty?
            messages.shift
          }
          message = @host.receive(message)
          message && message.send_response
        end
      end
    end
  end
end
