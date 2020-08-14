# frozen_string_literal: true

module Solargraph
  module Convention
    class Base
      EMPTY_ENVIRON = Environ.new

      # The Environ for a source map.
      # Subclasses can override this method.
      #
      # @param source_map [SourceMap]
      # @return [Environ]
      def local source_map
        EMPTY_ENVIRON
      end

      # The Environ for an api map.
      # Subclasses can override this method.
      #
      # @param yard_map [YardMap]
      # @return [Environ]
      def global yard_map
        EMPTY_ENVIRON
      end
    end
  end
end
