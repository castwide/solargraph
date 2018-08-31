module Solargraph
  class Source
    class Clip
      # @param api_map [ApiMap]
      # @param fragment [Fragment]
      def initialize api_map, fragment
        @api_map = api_map
        @fragment = fragment
      end

      def define
        @fragment.chain.define(api_map, fragment.context, fragment.locals)
      end

      def complete
      end

      def signify
      end

      private

      # @return [ApiMap]
      attr_reader :api_map

      # @return [Fragment]
      attr_reader :fragment
    end
  end
end
