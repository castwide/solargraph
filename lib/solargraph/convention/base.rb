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

      # Provides any additional method pins based on e the described object.
      #
      # @param api_map [ApiMap]
      # @param rooted_tag [String] A fully qualified namespace, with
      #   generic parameter values if applicable
      # @param scope [Symbol] :class or :instance
      # @param visibility [Array<Symbol>] :public, :protected, and/or :private
      # @param deep [Boolean]
      # @param skip [Set<String>]
      # @param no_core [Boolean] Skip core classes if true
      #
      # @return [Environ]
      def object api_map, rooted_tag, scope, visibility,
                 deep, skip, no_core
        EMPTY_ENVIRON
      end
    end
  end
end
