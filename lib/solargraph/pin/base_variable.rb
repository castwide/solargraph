module Solargraph
  module Pin
    class BaseVariable < Base
      attr_reader :signature

      attr_reader :context

      def initialize location, namespace, name, comments, signature, literal, context
        super(location, namespace, name, comments)
        @signature = signature
        @literal = literal
        @context = context
      end

      def scope
        @scope ||= (context.kind == Pin::METHOD and context.scope == :instance ? :instance : :class)
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::VARIABLE
      end

      # @return [Integer]
      def symbol_kind
        Solargraph::LanguageServer::SymbolKinds::VARIABLE
      end

      def return_complex_types
        @return_complex_types ||= generate_complex_types
      end

      def nil_assignment?
        return_type == 'NilClass'
      end

      def variable?
        true
      end

      def == other
        return false unless super
        signature == other.signature
      end

      def try_merge! pin
        return false unless super
        @signature = pin.signature
        @return_complex_types = pin.return_complex_types
        true
      end

      private

      def generate_complex_types
        unless docstring.nil?
          tag = docstring.tag(:type)
          return ComplexType.parse(*tag.types) unless tag.nil?
        end
        return ComplexType.parse(@literal) unless @literal.nil?
        []
      end
    end
  end
end
