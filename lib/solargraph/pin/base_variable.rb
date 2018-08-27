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

      def return_complex_type
        @return_complex_type ||= generate_complex_type
      end

      def nil_assignment?
        return_type == 'NilClass'
      end

      def variable?
        true
      end

      def infer api_map
        result = super
        return result if result.defined? or signature.nil?
        # @todo Instead of parsing a signature, start with an assignment node
        chain = Source::Chain.load_string(signature)
        fragment = api_map.fragment_at(location)
        chain.infer_type_with(api_map, context, fragment.locals)
      end

      def == other
        return false unless super
        signature == other.signature
      end

      def try_merge! pin
        return false unless super
        @signature = pin.signature
        @return_complex_type = pin.return_complex_type
        true
      end

      private

      def generate_complex_type
        tag = docstring.tag(:type)
        return ComplexType.parse(*tag.types) unless tag.nil?
        return ComplexType.parse(@literal) unless @literal.nil?
        ComplexType.new
      end
    end
  end
end
