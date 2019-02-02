module Solargraph
  module Pin
    module Common
      attr_reader :location

      # @return [Pin::Base, nil]
      attr_reader :closure

      # @return [String]
      def name
        @name ||= ''
      end

      def kind
        @kind ||= Pin::KEYWORD
      end

      def return_type
        @return_type ||= ComplexType::UNDEFINED
      end

      # @return [ComplexType]
      def context
        # Get the static context from the nearest namespace
        @context ||= find_context
      end

      def namespace
        context.namespace
      end

      # @return [ComplexType]
      def binder
        @binder || context
      end

      def comments
        @comments ||= ''
      end

      def path
        @path ||= name.empty? ? context.namespace : "#{context.namespace}::#{name}"
      end

      private

      # @return [ComplexType]
      def find_context
        here = self
        until here.nil?
          return Solargraph::ComplexType.parse(here.path) if here.kind == Pin::NAMESPACE
          here = here.closure
        end
        ComplexType::ROOT
      end
    end
  end
end
