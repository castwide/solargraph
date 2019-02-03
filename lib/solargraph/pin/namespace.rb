module Solargraph
  module Pin
    class Namespace < Closure
      # @return [Symbol] :public or :private
      attr_reader :visibility

      # @return [Symbol] :class or :module
      attr_reader :type

      # def initialize location, namespace, name, comments, type, visibility
      def initialize type: :class, visibility: :public, **splat
        # super(location, namespace, name, comments)
        super(splat)
        @type = type
        @visibility = visibility
        if name.start_with?('::')
          @name = name[2..-1]
          @closure = Pin::ROOT_PIN
        end
      end

      def namespace
        context.namespace
      end

      def kind
        Pin::NAMESPACE
      end

      # def context
      #   @context ||= ComplexType.parse("#{type.to_s.capitalize}<#{path}>")
      # end

      def scope
        context.scope
      end

      def completion_item_kind
        (type == :class ? LanguageServer::CompletionItemKinds::CLASS : LanguageServer::CompletionItemKinds::MODULE)
      end

      # @return [Integer]
      def symbol_kind
        (type == :class ? LanguageServer::SymbolKinds::CLASS : LanguageServer::SymbolKinds::MODULE)
      end

      def path
        @path ||= (namespace.empty? ? '' : "#{namespace}::") + name
      end

      def return_type
        @return_type ||= ComplexType.parse( (type == :class ? 'Class' : 'Module') + "<#{path}>" )
      end

      def domains
        @domains ||= []
      end

      def typify api_map
        return_type
      end
    end
  end
end
