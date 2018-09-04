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
        if @return_complex_type.nil?
          @return_complex_type = ComplexType::UNDEFINED
          tag = docstring.tag(:return)
          @return_complex_type = ComplexType.parse(*tag.types) unless tag.nil?
        end
        @return_complex_type
      end

      def parameters
        # Since attributes are generally equivalent to methods, treat
        # them as methods without parameters
        []
      end

      def parameter_names
        []
      end
    end
  end
end
