# frozen_string_literal: true

module Solargraph
  module LanguageServer
    class Host
      # A serial worker Thread to handle message.
      #
      # this make check pending message possible, and maybe cancelled to speedup process
      #
      class MessageWorker
        UPDATE_METHODS = ['textDocument/didOpen', 'textDocument/didChange', 'workspace/didChangeWatchedFiles'].freeze

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

        # @param message [Hash] The message to handle. Will be forwarded to Host#receive
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
            next_message
          end
          handler = @host.receive(message)
          handler&.send_response
        end

        private

        def next_message
          # Prioritize updates and version-dependent messages for performance
          idx = messages.find_index do |msg|
            UPDATE_METHODS.include?(msg['method']) || version_dependent?(msg)
          end
          # @todo We might want to clear duplicate instances of this message
          #   that occur before the next update
          return messages.shift unless idx

          msg = messages[idx]
          messages.delete_at idx
          msg
        end

        # True if the message requires a previous update to have executed in
        # order to work correctly.
        #
        def version_dependent? msg
          msg['textDocument'] && msg['position']
        end
      end
    end
  end
end
