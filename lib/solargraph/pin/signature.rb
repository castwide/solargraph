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

      # The index of the first parameter typed exactly
      # `<namespace>::_Key` - the position RBS uses to mark "this
      # parameter is a lookup key for this class's own K" (e.g.
      # `Hash#fetch: (Hash::_Key key) -> V`) - or nil if none of this
      # signature's parameters have that shape.
      #
      # This matches by the interface's literal name, so it only
      # recognizes RBS's own `Hash::_Key` - a user-defined generic
      # class using the same "marker interface for a lookup key"
      # pattern under a different name/namespace won't be detected.
      #
      # TODO once castwide/solargraph#1266 (structurally verify RBS
      # interface-typed expectations) lands - it lands with
      # ApiMap#get_own_methods (a namespace's directly-declared
      # methods, excluding inherited ones), extracted from
      # Conformance#required_interface_methods for exactly this reuse.
      # Replace the literal name comparison below with a structural
      # one: a parameter is key-shaped if its type is an interface
      # whose own declared method names equal
      # `Hash::_Key`'s (`hash`/`eql?`), regardless of the interface's
      # actual name -
      # https://github.com/castwide/solargraph/pull/1231#issuecomment-5207523909
      #
      #   def key_param_index namespace, api_map
      #     key_interface_methods = api_map.get_own_methods("#{namespace}::_Key").map(&:name).to_set
      #     parameters.find_index do |p|
      #       type = p.typify(api_map)
      #       next false unless type.interface?
      #       api_map.get_own_methods(type.tag).map(&:name).to_set == key_interface_methods
      #     end
      #   end
      #
      # @param namespace [String]
      # @param api_map [ApiMap]
      # @return [Integer, nil]
      def key_param_index namespace, api_map
        key_tag = "#{namespace}::_Key"
        parameters.find_index { |p| p.typify(api_map).tag == key_tag }
      end
    end
  end
end
