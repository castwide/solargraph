require 'reverse_markdown'

module Solargraph
  module Pin
    class Base
      include Conversions
      include Documenting

      attr_reader :location

      # @return [String]
      attr_reader :namespace

      attr_reader :name

      attr_reader :docstring

      # @return [String]
      attr_reader :return_type

      attr_reader :kind

      attr_reader :path

      def initialize location, namespace, name, docstring
        @location = location
        @namespace = namespace
        @name = name
        @docstring = docstring
      end

      def filename
        location.filename
      end

      # @return [String]
      def path
      end

      # @return [Integer]
      def kind
      end

      def completion_item_kind
        LanguageServer::CompletionItemKinds::KEYWORD
      end

      def to_s
        name.to_s
      end

      def identifier
        @identifier ||= "#{path}|#{name}"
      end

      def variable?
        false
      end

      def named_context
        namespace
      end
    end
  end
end
