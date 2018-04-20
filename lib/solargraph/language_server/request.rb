module Solargraph
  module LanguageServer
    class Request
      def initialize id, &block
        @id = id
        @block = block
      end

      def process result
        @block.call(result)
      end
    end
  end
end
