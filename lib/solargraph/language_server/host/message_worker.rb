# frozen_string_literal: true

module Solargraph
  module LanguageServer
    class Host
      # A serial worker Thread to handle incoming messages.
      #
      class MessageWorker
        UPDATE_METHODS = [
          'textDocument/didChange',
          'textDocument/didClose',
          'textDocument/didOpen',
          'textDocument/didSave',
          'workspace/didChangeConfiguration',
          'workspace/didChangeWatchedFiles',
          'workspace/didCreateFiles',
          'workspace/didChangeWorkspaceFolders',
          'workspace/didDeleteFiles',
          'workspace/didRenameFiles'
        ].freeze

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
          cancel_message || next_priority
        end

        def cancel_message
          # Handle cancellations first
          idx = messages.find_index { |msg| msg['method'] == '$/cancelRequest' }
          return unless idx

          msg = messages[idx]
          messages.delete_at idx
          msg
        end

        def next_priority
          # Prioritize updates and version-dependent messages for performance
          idx = messages.find_index do |msg|
            UPDATE_METHODS.include?(msg['method']) || version_dependent?(msg)
          end
          idx ? messages.delete_at(idx) : messages.shift
        end

        # True if the message requires a previous update to have executed in
        # order to work correctly.
        #
        # @param msg [Hash{String => Object}]
        # @todo need boolish type from RBS
        # @return [Object]
        def version_dependent? msg
          msg['textDocument'] && msg['position']
        end
      end
    end
  end
end
