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

      # @return [Integer]
      def symbol_kind
        nil
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

      def == other
        return false unless self.class == other.class
        location == other.location and
          namespace == other.namespace and
          name == other.name and
          ( (docstring.nil? and other.docstring.nil?) or (docstring == other.docstring and docstring.all == other.docstring.all) )
      end
    end
  end
end
