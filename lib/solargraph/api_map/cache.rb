# frozen_string_literal: true

module Solargraph
  class ApiMap
    class Cache
      def initialize
        # @type [Hash{Array => Array<Pin::Method>}]
        @methods = {}
        # @type [Hash{(String, Array<String>) => Array<Pin::Base>}]
        @constants = {}
        # @type [Hash{(String, String) => String}]
        @qualified_namespaces = {}
        # @type [Hash{String => Pin::Method}]
        @receiver_definitions = {}
        # @type [Hash{String => SourceMap::Clip}]
        @clips = {}
      end

      # @param fqns [String]
      # @param scope [Symbol]
      # @param visibility [Array<Symbol>]
      # @param deep [Boolean]
      # @return [Array<Pin::Method>]
      def get_methods fqns, scope, visibility, deep
        @methods["#{fqns}|#{scope}|#{visibility}|#{deep}"]
      end

      # @param fqns [String]
      # @param scope [Symbol]
      # @param visibility [Array<Symbol>]
      # @param deep [Boolean]
      # @param value [Array<Pin::Method>]
      # @return [void]
      def set_methods fqns, scope, visibility, deep, value
        @methods["#{fqns}|#{scope}|#{visibility}|#{deep}"] = value
      end

      # @param namespace [String]
      # @param contexts [Array<String>]
      # @return [Array<Pin::Base>]
      def get_constants namespace, contexts
        @constants["#{namespace}|#{contexts}"]
      end

      # @param namespace [String]
      # @param contexts [Array<String>]
      # @param value [Array<Pin::Base>]
      # @return [void]
      def set_constants namespace, contexts, value
        @constants["#{namespace}|#{contexts}"] = value
      end

      # @param name [String]
      # @param context [String]
      # @return [String]
      def get_qualified_namespace name, context
        @qualified_namespaces["#{name}|#{context}"]
      end

      # @param name [String]
      # @param context [String]
      # @param value [String]
      # @return [void]
      def set_qualified_namespace name, context, value
        @qualified_namespaces["#{name}|#{context}"] = value
      end

      # @param path [String]
      # @return [Pin::Method]
      def get_receiver_definition path
        @receiver_definitions[path]
      end

      # @param path [String]
      # @param pin [Pin::Method]
      # @return [void]
      def set_receiver_definition path, pin
        @receiver_definitions[path] = pin
      end

      # @param cursor [Source::Cursor]
      # @return [SourceMap::Clip, nil]
      def get_clip(cursor)
        @clips["#{cursor.filename}|#{cursor.range.inspect}|#{cursor.node&.to_sexp}"]
      end

      # @param cursor [Source::Cursor]
      # @param clip [SourceMap::Clip]
      def set_clip(cursor, clip)
        @clips["#{cursor.filename}|#{cursor.range.inspect}|#{cursor.node&.to_sexp}"] = clip
      end

      # @return [void]
      def clear
        all_caches.each(&:clear)
      end

      # @return [Boolean]
      def empty?
        all_caches.all?(&:empty?)
      end

      private

      def all_caches
        [@methods, @constants, @qualified_namespaces, @receiver_definitions, @clips]
      end
    end
  end
end
