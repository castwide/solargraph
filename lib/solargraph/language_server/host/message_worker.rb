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
        # @return [Array<Hash>]
        def messages
          @messages ||= []
        end

        def stopped?
          @stopped
        end

        # @return [void]
        def stop
          @stopped = true
        end

        # @param message [Hash] The message should be handle. will pass back to Host#receive
        # @return [void]
        def queue(message)
          @mutex.synchronize do
            messages.push(message)
            @resource.signal
          end
        end

        # @return [void]
        def start
          return unless @stopped
          @stopped = false
          Thread.new do
            tick until stopped?
          end
        end

        # @return [void]
        def tick
          message = @mutex.synchronize do
            @resource.wait(@mutex) if messages.empty?
            messages.shift
          end
          handler = @host.receive(message)
          handler && handler.send_response
        end
      end
    end
  end
end
