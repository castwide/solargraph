# frozen_string_literal: true

module Solargraph
  module Typedef
    class Generics
      # @param pin [Pin::Base]
      # @param receiver [Pin::Closure]
      # @return [Pin::Base]
      def self.expand api_map, pin, receiver
        expand_generic_types(api_map, pin, receiver)
      end

      def self.expand_generic_types api_map, pin, receiver
        pin.typedef_return_types
           .map { |type| type.expand zip_pin_generic_values(api_map, pin, receiver) }
           .map { |type| type.expand zip_receiver_generic_values(api_map, pin, receiver) }
      end

      def self.zip_pin_generic_values api_map, pin, receiver
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

      def self.zip_receiver_generic_values api_map, pin, receiver
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
