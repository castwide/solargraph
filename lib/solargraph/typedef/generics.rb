# frozen_string_literal: true

module Solargraph
  module Typedef
    # Contextual expansion of generic tokens
    #
    class Generics
      # @return [ApiMap]
      attr_reader :api_map

      # @return [Pin::Base]
      attr_reader :pin

      # @return [Pin::Closure]
      attr_reader :receiver

      def initialize api_map, pin, receiver
        @api_map = api_map
        @pin = pin
        @receiver = receiver
      end

      def expand
        pin.typedef_return_types
           .map { |type| type.expand zip_generic_values(pin) }
           .map { |type| type.expand zip_generic_values(receiver) }
      end

      def names
        generics_from(pin).concat(generics_from(receiver))
      end

      def self.expand api_map, pin, receiver
        new(api_map, pin, receiver).expand
      end

      private

      # @param pin [Pin::Base]
      def generics_from pin
        names = []
        cursor = pin
        while cursor
          names.concat(cursor.typedef_generics)
          cursor = cursor.closure
        end
        names
      end

      def expand_generic_types
        types = pin.typedef_return_types
           .map { |type| type.expand zip_pin_generic_values }
           .map { |type| type.expand zip_receiver_generic_values }
        pin.proxy(ComplexType.new(types.map(&:to_complex_type)))
      end

      # @param reference [Pin::Base] The pin with the @generic tag(s)
      def zip_generic_values reference
        generic_names = names.map { |name| "generic<#{name}>"}
        type = unless generic_names.empty?
          receiver.typedef_return_types.find { |type| type.base.to_s == reference.context.namespace && type.params.length == generic_names.length } ||
            receiver.typedef_return_types.find { |type| type.base.to_s == receiver.context.namespace && type.params.length == generic_names.length }
        end
        named_values = if type
          generic_names.zip(type.params).to_h
        else
          {}
        end
      end
    end
  end
end
