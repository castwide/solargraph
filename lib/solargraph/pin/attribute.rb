module Solargraph
  module Pin
    class Attribute < Base
      # @return [Symbol] :reader or :writer
      attr_reader :access

      # @return [Symbol] :class or :instance
      attr_reader :scope

      # @return [Symbol] :public, :protected, or :private
      attr_reader :visibility

      def initialize location, namespace, name, comments, access, scope, visibility
        super(location, namespace, name, comments)
        @access = access
        @scope = scope
        @visibility = visibility
      end

      def kind
        Solargraph::Pin::ATTRIBUTE
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::PROPERTY
      end

      def symbol_kind
        Solargraph::LanguageServer::SymbolKinds::PROPERTY
      end

      def path
        @path ||= namespace + (scope == :instance ? '#' : '.') + name
      end

      def return_complex_type
        @return_complex_type ||= generate_complex_type
      end

      def parameters
        # Since attributes are generally equivalent to methods, treat
        # them as methods without parameters
        []
      end

      def parameter_names
        []
      end

      private

      # @todo DRY this method. It also exists in Pin::Method.
      #
      # @return [ComplexType]
      def generate_complex_type
        tag = docstring.tag(:return)
        if tag.nil?
          ol = docstring.tag(:overload)
          tag = ol.tag(:return) unless ol.nil?
        end
        return ComplexType::UNDEFINED if tag.nil? or tag.types.nil? or tag.types.empty?
        begin
          ComplexType.parse *tag.types
        rescue Solargraph::ComplexTypeError => e
          STDERR.puts e.message
          ComplexType::UNDEFINED
        end
      end
    end
  end
end
