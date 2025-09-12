module Solargraph
  module Pin
    class Signature < Callable
      # allow signature to be created before method pin, then set this
      # to the method pin
      attr_writer :closure

      def initialize **splat
        super(**splat)
      end

      # @sg-ignore Need to understand @foo ||= 123 will never be nil
      def generics
        @generics ||= [].freeze
      end

      # @sg-ignore Need to understand @foo ||= 123 will never be nil
      def identity
        @identity ||= "signature#{object_id}"
      end

      attr_writer :closure

      # @sg-ignore need boolish support for ? methods
      def dodgy_return_type_source?
        super || closure&.dodgy_return_type_source?
      end

      # @sg-ignore need boolish support for ? methods
      def type_location
        super || closure&.type_location
      end

      # @sg-ignore need boolish support for ? methods
      def location
        super || closure&.location
      end

      def typify api_map
        if return_type.defined?
          qualified = return_type.qualify(api_map, closure.namespace)
          logger.debug { "Signature#typify(self=#{self}) => #{qualified.rooted_tags.inspect}" }
          return qualified
        end
        return ComplexType::UNDEFINED if closure.nil?
        return ComplexType::UNDEFINED unless closure.is_a?(Pin::Method)
        # @sg-ignore need is_a? support
        # @type [Array<Pin::Method>]
        method_stack = closure.rest_of_stack api_map
        logger.debug { "Signature#typify(self=#{self}) - method_stack: #{method_stack}" }
        method_stack.each do |pin|
          sig = pin.signatures.find { |s| s.arity == self.arity }
          next unless sig
          unless sig.return_type.undefined?
            qualified = sig.return_type.qualify(api_map, closure.namespace)
            logger.debug { "Signature#typify(self=#{self}) => #{qualified.rooted_tags.inspect}" }
            return qualified
          end
        end
        out = super
        logger.debug { "Signature#typify(self=#{self}) => #{out}" }
        out
      end
    end
  end
end
