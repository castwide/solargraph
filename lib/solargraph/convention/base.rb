# frozen_string_literal: true

module Solargraph
  module Convention
    # The base class for Conventions.
    #
    # A Convention provides Environs that customize ApiMaps with additional
    # pins and other information. Subclasses should implement the `local` and
    # `global` methods as necessary.
    #
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

      # The Environ for a DocMap.
      # Subclasses can override this method.
      #
      # @param doc_map [DocMap]
      # @return [Environ]
      def global doc_map
        EMPTY_ENVIRON
      end
    end
  end
end
