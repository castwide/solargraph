# frozen_string_literal: true

module Solargraph
  module Pin
    module Common
      # @!method source
      #   @abstract
      #   @return [Source, nil]
      # @type @closure [Pin::Closure, nil]

      # @return [Location]
      attr_reader :location

      # @sg-ignore Solargraph::Pin::Common#closure return type could not be inferred
      # @return [Pin::Closure, nil]
      def closure
        unless @closure
          Solargraph.assert_or_log(:closure,
                                   "Closure not set on #{self.class} #{name.inspect} from #{source.inspect}")
        end
        @closure
      end

      # @return [String]
      def name
        @name ||= ''
      end

      # @return [ComplexType]
      def return_type
        @return_type ||= ComplexType::UNDEFINED
      end

      # @return [ComplexType]
      def context
        # Get the static context from the nearest namespace
        @context ||= find_context
      end
      alias full_context context

      # @return [String]
      def namespace
        context.namespace.to_s
      end

      # @return [ComplexType]
      def binder
        @binder || context
      end

      # @return [String]
      def comments
        @comments ||= ''
      end

      # @return [String]
      def path
        @path ||= name.empty? ? context.namespace : "#{context.namespace}::#{name}"
      end

      protected

      attr_writer :context

      private

      # @return [ComplexType]
      def find_context
        here = closure
        until here.nil?
          if here.is_a?(Pin::Namespace)
            return here.return_type
          elsif here.is_a?(Pin::Method)
            return here.context
          end
          here = here.closure
        end
        ComplexType::ROOT
      end
    end
  end
end
