module Solargraph
  module Pin
    class Namespace < Closure
      # @return [::Symbol] :public or :private
      attr_reader :visibility

      # @return [::Symbol] :class or :module
      attr_reader :type

      # @return [String]
      attr_reader :gate

      # @param type [Symbol] :class or :module
      # @param visibility [Symbol] :public or :private
      # @param gated [Boolean] True if this namespace opens a scope gate
      def initialize type: :class, visibility: :public, gated: true, **splat
        # super(location, namespace, name, comments)
        super(splat)
        @type = type
        @visibility = visibility
        if name.start_with?('::')
          @name = name[2..-1]
          @closure = Pin::ROOT_PIN
        end
        if gated
          @gate = @name
          if @gate.include?('::')
            parts = @gate.split('::')
            @name = parts.last
            adjusted = (@closure ? @closure.path : Pin::ROOT_PIN.path).split('::') + parts[0..-2]
            @closure = Pin::Namespace.new(name: adjusted.join('::'), gated: false)
            @context = nil
          end
        else
          @gate = ''
        end
      end

      def namespace
        context.namespace
      end

      def full_context
        @full_context ||= ComplexType.try_parse("#{type.to_s.capitalize}<#{path}>")
      end

      def binder
        full_context
      end

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
        @return_type ||= ComplexType.try_parse( (type == :class ? 'Class' : 'Module') + "<#{path}>" )
      end

      def domains
        @domains ||= []
      end

      def typify api_map
        return_type
      end

      # Get an array of all the open scope gates in the current context.
      #
      # @return [Array<String>]
      def gates
        return [gate] if gate.empty?
        @gates ||= begin
          result = [gate]
          clos = closure
          until clos.nil?
            result.push clos.gate if clos.is_a?(Pin::Namespace)
            break if result.last.empty?
            clos = clos.closure
          end
          result
        end
      end
    end
  end
end
