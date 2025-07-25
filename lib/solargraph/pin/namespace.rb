# frozen_string_literal: true

require 'solargraph/yard_tags'

module Solargraph
  module Pin
    class Namespace < Closure
      # @return [::Symbol] :public or :private
      attr_reader :visibility

      # @return [::Symbol] :class or :module
      attr_reader :type

      # does not assert like super, as a namespace without a closure
      # may be the root level namespace, or it may not yet be
      # qualified
      attr_reader :closure

      # @param type [::Symbol] :class or :module
      # @param visibility [::Symbol] :public or :private
      # @param gates [::Array<String>]
      # @param name [String]
      def initialize type: :class, visibility: :public, gates: [''], name: '', **splat
        # super(location, namespace, name, comments)
        super(**splat, name: name)
        @type = type
        @visibility = visibility
        if name.start_with?('::')
          # @type [String]
          name = name[2..-1] || ''
          @closure = Solargraph::Pin::ROOT_PIN
        end
        @open_gates = gates
        if name.include?('::')
          # In this case, a chained namespace was opened (e.g., Foo::Bar)
          # but Foo does not exist.
          parts = name.split('::')
          name = parts.pop
          closure_name = if [Solargraph::Pin::ROOT_PIN, nil].include?(closure)
            ''
          else
            closure.full_context.namespace + '::'
          end
          closure_name += parts.join('::')
          @closure = Pin::Namespace.new(name: closure_name, gates: [parts.join('::')], source: :namespace)
          @context = nil
        end
        @name = name
      end

      def to_rbs
        "#{@type.to_s} #{return_type.all_params.first.to_rbs}#{rbs_generics}".strip
      end

      def inner_desc
        if name.nil? || name.empty?
          '(top-level)'
        else
          super
        end
      end

      def namespace
        context.namespace
      end

      def full_context
        @full_context ||= ComplexType.try_parse("::#{type.to_s.capitalize}<#{path}>")
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

      # @return [String]
      def path
        @path ||= (namespace.empty? ? '' : "#{namespace}::") + name
      end

      def return_type
        @return_type ||= ComplexType.try_parse( (type == :class ? '::Class' : '::Module') + "<::#{path}>")
      end

      # @return [Array<String>]
      def domains
        @domains ||= []
      end

      def typify api_map
        return_type
      end

      def gates
        @gates ||= if path.empty?
          @open_gates
        else
          [path] + @open_gates
        end
      end
    end
  end
end
