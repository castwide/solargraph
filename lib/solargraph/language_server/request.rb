# frozen_string_literal: true

module Solargraph
  module LanguageServer
    class Request
      # @param id [Integer]
      # @param block [Proc] The block that processes the client's response
      def initialize id, &block
        @id = id
        @block = block
      end

      # @sg-ignore Solargraph::LanguageServer::Request#process return
      #   type could not be inferred
      # @param result [Object]
      # @generic T
      # @yieldreturn [generic<T>]
      # @return [generic<T>, nil]
      def process result
        @block&.call(result)
      end

      # @return [void]
      def send_response
        # noop
      end
    end
  end
end
