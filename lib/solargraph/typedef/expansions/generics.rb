# frozen_string_literal: true

module Solargraph
  module Typedef
    module Expansions
      # Contextual expansion of generic tokens
      #
      class Generics < Base
        def expand
          pin.typedef_typeset
             .expand(zip_generic_values)
             .expand(closure_generic_values)
        end

        def names
          generics_from(pin).concat(generics_from(receiver))
        end

        # Generic tokens defined by namespaces a step away from the pin,
        # e.g. the element type of the Enumerable module that supplies
        # #map, zipped by position against the receiver's parameters. Unlike
        # #names, generics declared by the pin itself, such as a method's
        # own type parameters, are excluded since they cannot be derived
        # from the receiver.
        #
        # @return [Hash{String => Object}]
        def closure_generic_values
          @closure_generic_values ||= begin
            closure_names = closure_generic_names
            type = find_matching_receiver_type(closure_names)
            if type
              closure_names.map { |name| "generic<#{name}>" }.zip(type.params).to_h
            else
              {}
            end
          end
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

        # Generic names declared by the namespaces in the pin's closure
        # chain and the receiver's closure chain. Method-level generics
        # are skipped.
        #
        # @return [Array<String>]
        def closure_generic_names
          names = []
          cursor = pin&.closure
          while cursor
            names.concat(cursor.typedef_generics) if cursor.is_a?(Pin::Namespace)
            cursor = cursor.closure
          end
          cursor = receiver
          while cursor
            names.concat(cursor.typedef_generics) if cursor.is_a?(Pin::Namespace)
            cursor = cursor.closure
          end
          names.uniq
        end

        # @return [Hash{String => Object}]
        def zip_generic_values
          generic_names = names.map { |name| "generic<#{name}>" }
          type = find_matching_receiver_type(names)
          type ? generic_names.zip(type.params).to_h : {}
        end

        # The first flat type in the receiver whose number of parameters
        # matches the given generic names.
        #
        # @param names [Array<String>]
        # @return [Typedef::Type, nil]
        def find_matching_receiver_type names
          return nil if names.empty? || receiver.nil?
          typeset = receiver.typedef_typeset
          return nil if typeset.nil?
          typeset.flat_types.find { |type| type.params.length == names.length }
        rescue StandardError => _e
          nil
        end
      end
    end
  end
end
