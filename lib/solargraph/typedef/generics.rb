# frozen_string_literal: true

module Solargraph
  module Typedef
    # Contextual expansion of generic tokens
    #
    class Generics
      attr_reader :api_map

      attr_reader :pin

      attr_reader :receiver

      def initialize api_map, pin, receiver
        @api_map = api_map
        @pin = pin
        @receiver = receiver
      end

      def expand
        pin.typedef_return_types
           .map { |type| type.expand zip_pin_generic_values }
           .map { |type| type.expand zip_receiver_generic_values }
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

      def zip_pin_generic_values
        generic_names = pin.closure.docstring.tags(:generic).map(&:name).map { |name| "generic<#{name}>"}
        type = unless generic_names.empty?
          receiver.typedef_return_types.find { |type| type.base.to_s == pin.context.namespace && type.params.length == generic_names.length }
        end
        named_values = if type
          generic_names.zip(type.params).to_h
        else
          {}
        end
        named_values.merge({'self' => receiver.binder.namespace})
      end

      def zip_receiver_generic_values
        # namespaces = api_map.get_path_pins(receiver.namespace).select { |pin| pin.is_a?(Pin::Namespace) }
        # generic_names = namespaces.flat_map(&:generics).map { |name| "generic<#{name}>"}
        # return {} unless receiver.closure

        # generic_names = receiver.closure.generics.map { |name| "generic<#{name}>"}
        generic_names = receiver.docstring.tags(:generic).map(&:name).map { |name| "generic<#{name}>"}

        type = unless generic_names.empty?
          receiver.closure.typedef_return_types.find { |type| type.base.to_s == receiver.namespace && type.params.length == generic_names.length }
        end

        named_values = if type
          generic_names.zip(type.params).to_h
        else
          {}
        end
        named_values.merge({'self' => receiver.binder.namespace})
      end
    end
  end
end
