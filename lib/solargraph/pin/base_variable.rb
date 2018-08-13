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

      def return_type
        # if @return_type.nil?
        #   if !docstring.nil?
        #     tag = docstring.tag(:type)
        #     @return_type = tag.types[0] unless tag.nil?
        #   else
        #     @return_type = @literal
        #   end
        # end
        # @return_type
        if @return_type.nil?
          if return_complex_types.empty?
            @return_type = @literal
          else
            @return_type = return_complex_types.first.tag
          end
        end
        @return_type
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

      def nearly? other
        return false unless super
        signature == other.signature
      end

      private

      def generate_complex_types
        return [] if docstring.nil?
        tag = docstring.tag(:type)
        return [] if tag.nil?
        ComplexType.parse *tag.types
      end
    end
  end
end
