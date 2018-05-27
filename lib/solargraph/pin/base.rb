require 'reverse_markdown'

module Solargraph
  module Pin
    class Base
      include Conversions
      include Documenting

      # @return [Solargraph::Source::Location]
      attr_reader :location

      # @return [String]
      attr_reader :namespace

      # @return [String]
      attr_reader :name

      # @return [YARD::Docstring]
      attr_reader :docstring

      # @return [String]
      attr_reader :return_type

      # @return [Integer]
      attr_reader :kind

      # @return [String]
      attr_reader :path

      def initialize location, namespace, name, docstring
        @location = location
        @namespace = namespace
        @name = name
        @docstring = docstring
      end

      # @return [String]
      def filename
        location.filename
      end

      # @return [Integer]
      def completion_item_kind
        LanguageServer::CompletionItemKinds::KEYWORD
      end

      def to_s
        name.to_s
      end

      # @return [String]
      def identifier
        @identifier ||= "#{path}|#{name}"
      end

      def variable?
        false
      end

      # @return [String]
      def named_context
        namespace
      end

      def return_namespace
        return nil if complex_types.empty?
        @return_namespace ||= complex_types.first.namespace
      end

      def return_scope
        return nil if complex_types.empty?
        @return_scope ||= complex_types.first.scope
      end

      # @return [Array<ComplexType>]
      def complex_types
        []
      end
    end
  end
end
