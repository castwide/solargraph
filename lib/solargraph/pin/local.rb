module Solargraph
  module Pin
    class Local < Base
      # @return [Solargraph::Source::Range]
      attr_reader :presence

      def initialize location, namespace, name, docstring, presence
        super(location, namespace, name, docstring)
        @presence = presence
      end
    end
  end
end
