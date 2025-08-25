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
      # @param [Object] _source_map
      def local _source_map
        EMPTY_ENVIRON
      end

      # The Environ for a DocMap.
      # Subclasses can override this method.
      #
      # @param doc_map [DocMap]
      # @return [Environ]
      # @param [Object] _doc_map
      def global _doc_map
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
      # @param [Object] _api_map
      # @param [Object] _rooted_tag
      # @param [Object] _scope
      # @param [Object] _visibility
      # @param [Object] _deep
      # @param [Object] _skip
      # @param [Object] _no_core
      def object _api_map, _rooted_tag, _scope, _visibility,
                 _deep, _skip, _no_core
        EMPTY_ENVIRON
      end
    end
  end
end
