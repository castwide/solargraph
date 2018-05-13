module Solargraph
  module LanguageServer
    class Request
      def initialize id, &block
        @id = id
        @block = block
      end

      def process result
        @block.call(result) unless @block.nil?
      end

      def send
        # noop
      end
    end
  end
end
