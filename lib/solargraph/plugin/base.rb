module Solargraph
  module Plugin
    class Base
      attr_reader :workspace

      def initialize workspace
        @workspace = workspace
      end
    end
  end
end
