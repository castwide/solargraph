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

      # @return [Typeset]
      def expand
        pin.typedef_typeset
           .expand(zip_generic_values(pin))
           .expand(zip_generic_values(receiver))
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

      # @param reference [Pin::Base]
      def zip_generic_values reference
        generic_names = names.map { |name| "generic<#{name}>"}
        type = unless generic_names.empty?
          receiver.typedef_typeset.flat_types.find { |type| type.params.length == generic_names.length }
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
