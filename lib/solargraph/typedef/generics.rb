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
        types = pin.typedef_return_types
           .map { |type| type.expand zip_pin_generic_values }
           .map { |type| type.expand zip_receiver_generic_values }
        pin.proxy(ComplexType.new(types.map(&:to_complex_type)))
      end

      def self.expand api_map, pin, receiver
        new(api_map, pin, receiver).expand
      end

      private

      def expand_generic_types
        types = pin.typedef_return_types
           .map { |type| type.expand zip_pin_generic_values }
           .map { |type| type.expand zip_receiver_generic_values }
        pin.proxy(ComplexType.new(types.map(&:to_complex_type)))
      end

      def zip_pin_generic_values
        # @todo Figure this out. See spec/typedef/call_spec.rb:464
        #   ('sends proper gates in ProxyType')
        return {}
        generic_names = pin.docstring.tags(:generic).map(&:name).map { |name| "generic<#{name}>"}
        type = unless generic_names.empty?
          pin.closure.typedef_return_types.find { |type| type.params.first.to_s == pin.binder.namespace && type.params.length == generic_names.length }
        end
        named_values = if type
          generic_names.zip(type.params).to_h
        else
          {}
        end
        named_values.merge({'self' => receiver.binder.namespace})
      end

      def zip_receiver_generic_values
        namespaces = api_map.get_path_pins(receiver.namespace).select { |pin| pin.is_a?(Pin::Namespace) }
        generic_names = namespaces.flat_map(&:generics).map { |name| "generic<#{name}>"}

        type = unless generic_names.empty?
          receiver.typedef_return_types.find { |type| type.base.to_s == receiver.namespace && type.params.length == generic_names.length }
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
