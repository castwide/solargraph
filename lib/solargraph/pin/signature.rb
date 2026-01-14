module Solargraph
  module Pin
    class Signature < Callable
      # allow signature to be created before method pin, then set this
      # to the method pin
      attr_writer :closure

      def initialize **splat
        super(**splat)
      end

      def generics
        # @type [Array<::String, nil>]
        @generics ||= [].freeze
      end

      def identity
        @identity ||= "signature#{object_id}"
      end

      # @ sg-ignore need boolish support for ? methods
      def dodgy_return_type_source?
        super || closure&.dodgy_return_type_source?
      end

      def type_location
        super || closure&.type_location
      end

      def location
        super || closure&.location
      end

      def typify api_map
        # @sg-ignore Need to add nil check here
        if return_type.defined?
          # @sg-ignore Need to add nil check here
          qualified = return_type.qualify(api_map, closure.namespace)
          # @sg-ignore Need to add nil check here
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
          # @sg-ignore Need to add nil check here
          unless sig.return_type.undefined?
            # @sg-ignore Need to add nil check here
            qualified = sig.return_type.qualify(api_map, closure.namespace)
            # @sg-ignore Need to add nil check here
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
