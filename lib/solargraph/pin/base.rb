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

      # @return [String]
      attr_reader :comments

      # @return [Integer]
      attr_reader :kind

      # @return [String]
      attr_reader :path

      # @param location [Solargraph::Source::Location]
      # @param namespace [String]
      # @param name [String]
      # @param comments [String]
      def initialize location, namespace, name, comments
        @location = location
        @namespace = namespace
        @name = name
        @comments = comments || ''
      end

      # @return [String]
      def filename
        return nil if location.nil?
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

      def yard_pin?
        false
      end

      # @return [String]
      def named_context
        namespace
      end

      # Pin equality is determined using the #nearly? method and also
      # requiring both pins to have the same location.
      #
      def == other
        return false unless nearly? other
        location == other.location
      end

      # True if the specified pin is a near match to this one. A near match
      # indicates that the pins contain mostly the same data. Any differences
      # between them should not have an impact on the API surface.
      #
      # @param other [Solargraph::Pin::Base, Object]
      # @return [Boolean]
      def nearly? other
        return false unless self.class == other.class
        namespace == other.namespace and
          name == other.name and
          (comments == other.comments or
            ( ((maybe_directives? == false and other.maybe_directives? == false) or directives == other.directives) and
            docstring.tags == other.docstring.tags )
          )
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

      # @return [YARD::Docstring]
      def docstring
        parse_comments unless defined?(@docstring)
        @docstring ||= YARD::Docstring.parser.parse('').to_docstring
      end

      # @param [Array<YARD::Tags::Directive>]
      def directives
        parse_comments unless defined?(@directives)
        @directives
      end

      # Perform a quick check to see if this pin possibly includes YARD
      # directives. This method does not require parsing the comments.
      #
      # After the comments have been parsed, this method will return false if
      # no directives were found, regardless of whether it previously appeared
      # possible.
      #
      # @return [Boolean]
      def maybe_directives?
        return !@directives.empty? if defined?(@directives)
        @maybe_directives ||= comments.include?('@!')
      end

      # Try to merge data from another pin. Merges are only possible if the
      # pins are near matches (see the #nearly? method). The changes should
      # not have any side effects on the API surface.
      #
      # @param pin [Pin::Base] The pin to merge into this one
      # @return [Boolean] True if the pins were merged
      def try_merge! pin
        return false unless nearly?(pin)
        @location = pin.location
        if comments != pin.comments
          @comments = pin.comments
          @docstring = pin.docstring
          @return_complex_types = pin.return_complex_types
          @documentation = nil
          reset_conversions
        end
        true
      end

      private

      # @return [void]
      def parse_comments
        if comments.empty?
          @docstring = nil
          @directives = []
        else
          parse = YARD::Docstring.parser.parse(comments)
          @docstring = parse.to_docstring
          @directives = parse.directives
        end
      end
    end
  end
end
