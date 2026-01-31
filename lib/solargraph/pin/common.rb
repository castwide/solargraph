# frozen_string_literal: true

module Solargraph
  module Pin
    module Common
      # @!method source
      #   @abstract
      #   @return [Source, nil]
      # @!method reset_generated!
      #   @abstract
      #   @return [void]
      # @type @closure [Pin::Closure, nil]
      # @type @binder [ComplexType, ComplexType::UniqueType, nil]

      # @todo Missed nil violation
      # @return [Location, nil]
      attr_accessor :location

      # @param value [Pin::Closure]
      # @return [void]
      def closure=(value)
        @closure = value
        # remove cached values generated from closure
        reset_generated!
      end

      # @return [Pin::Closure, nil]
      def closure
        Solargraph.assert_or_log(:closure, "Closure not set on #{self.class} #{name.inspect} from #{source.inspect}") unless @closure
        @closure
      end

      # @return [String]
      def name
        @name ||= ''
      end

      # @todo redundant with Base#return_type?
      # @return [ComplexType]
      def return_type
        @return_type ||= ComplexType::UNDEFINED
      end

      # @return [ComplexType, ComplexType::UniqueType]
      def context
        # Get the static context from the nearest namespace
        @context ||= find_context
      end
      alias full_context context

      # @return [String]
      def namespace
        context.namespace.to_s
      end

      # @return [ComplexType, ComplexType::UniqueType]
      # @sg-ignore https://github.com/castwide/solargraph/pull/1100
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
          # @sg-ignore Need to add nil check here
          here = here.closure
        end
        ComplexType::ROOT
      end
    end
  end
end
