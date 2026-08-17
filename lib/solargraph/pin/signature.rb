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

      # The index of the first parameter acting as a Hash-like lookup
      # key for this class's own `K` (e.g. `Hash#fetch`'s first
      # parameter), or nil if no parameter has that shape.
      #
      # RBS's `core/hash.rbs` declares that parameter two ways, so both
      # are recognized: `(_Key key)` from RBS 4.1.0 on (matched by the
      # interface's literal name, so only RBS's own `Hash::_Key`), and
      # `(K arg0)` before it, where `K` has already been resolved
      # against the receiver - for a literal-keyed receiver that makes
      # it the literal key type `key_tags` matches against.
      #
      # @todo Match `_Key` structurally rather than by name once
      #   castwide/solargraph#1266 lands with ApiMap#get_own_methods -
      #   https://github.com/castwide/solargraph/pull/1231#issuecomment-5207523909
      #
      # @param namespace [String]
      # @param api_map [ApiMap]
      # @param key_tags [::Array<String>] the receiver's own resolved
      #   `key_types` tags, used to recognize the pre-4.1 `K`-typed
      #   shape. Empty disables that fallback.
      # @return [Integer, nil]
      def hash_key_param_index namespace, api_map, key_tags = []
        key_tag = "#{namespace}::_Key"
        index = parameters.find_index { |p| p.typify(api_map).tag == key_tag }
        return index unless index.nil?
        return nil if key_tags.empty?

        parameters.find_index { |p| key_tags.include?(p.typify(api_map).tag) }
      end
    end
  end
end
