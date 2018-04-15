module Solargraph
  module Pin
    class BaseVariable < Base
      attr_reader :signature

      attr_reader :context

      def initialize location, namespace, name, docstring, signature, literal, context
        super(location, namespace, name, docstring)
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

      def return_type
        if @return_type.nil?
          if !docstring.nil?
            tag = docstring.tag(:type)
            @return_type = tag.types[0] unless tag.nil?
          else
            @return_type = @literal
          end
        end
        @return_type
      end

      def nil_assignment?
        return_type == 'NilClass'
      end

      def variable?
        true
      end
    end
  end
end
