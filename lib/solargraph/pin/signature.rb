# frozen_string_literal: true

module Solargraph
  module Pin
    class Signature < Callable
      # allow signature to be created before method pin, then set this
      # to the method pin
      attr_writer :closure

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
          sig = pin.signatures.find { |s| s.arity == arity }
          next unless sig
          # @sg-ignore Need to add nil check here
          next if sig.return_type.undefined?
          # @sg-ignore Need to add nil check here
          qualified = sig.return_type.qualify(api_map, closure.namespace)
          # @sg-ignore Need to add nil check here
          logger.debug { "Signature#typify(self=#{self}) => #{qualified.rooted_tags.inspect}" }
          return qualified
        end
        out = super
        logger.debug { "Signature#typify(self=#{self}) => #{out}" }
        out
      end

      # The index of the first parameter typed as the receiver's own
      # key (e.g. `Hash#fetch`'s first parameter), or nil if none is.
      #
      # The parameter is declared `K`, which by this point has been
      # resolved against the receiver - for a literal-keyed receiver
      # that makes it the literal key type `key_tags` matches against.
      # RBS >= 4.1 declares it as the structural interface `Hash::_Key`
      # instead; RbsTranslator stubs that back to `K` on the way in
      # (see RBS_INTERFACE_TO_GENERIC), so only this one shape is left
      # to recognize here.
      #
      # @param api_map [ApiMap]
      # @param key_tags [::Array<String>] the receiver's own resolved
      #   `key_types` tags. Empty means there is nothing to match.
      # @return [Integer, nil]
      def hash_key_param_index api_map, key_tags
        return nil if key_tags.empty?

        parameters.find_index { |p| key_tags.include?(p.typify(api_map).tag) }
      end
    end
  end
end
