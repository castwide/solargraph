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

      # @return [Integer]
      attr_reader :kind

      # @return [String]
      attr_reader :path

      # @param location [Solargraph::Source::Location]
      # @param namespace [String]
      # @param name [String]
      # @param docstring [YARD::Docstring]
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

      # @return [Boolean]
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

      def nearly? other
        return false unless self.class == other.class
        namespace == other.namespace and
          name == other.name and
          ( (docstring.nil? and other.docstring.nil?) or (docstring == other.docstring and docstring.all == other.docstring.all) )
      end

      # The first return type associated with the pin.
      # Use return_complex_types for an array of all return types.
      #
      # @return [String]
      def return_type
        return nil if return_complex_types.empty?
        return_complex_types.first.tag
      end

      # The namespace of the first return type.
      # Use return_complex_types for an array of all return types.
      #
      # @return [String]
      def return_namespace
        return nil if return_complex_types.empty?
        @return_namespace ||= return_complex_types.first.namespace
      end

      # The scope of the first return type.
      # Use return_complex_types for an array of all return types.
      #
      # @return [String]
      def return_scope
        return nil if return_complex_types.empty?
        @return_scope ||= return_complex_types.first.scope
      end

      # All of the pin's return types as an array of ComplexTypes.
      #
      # @return [Array<ComplexType>]
      def return_complex_types
        @return_complex_types ||= []
      end
    end
  end
end
