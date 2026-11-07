# frozen_string_literal: true

module Solargraph
  module Typedef
    module Expansions
      # Contextual expansion of generic tokens
      #
      class Generics < Base
        # @return [Dictionary, nil]
        attr_reader :call_block

        # @param api_map [ApiMap]
        # @param pin [Pin::Base]
        # @param receiver [Pin::Closure]
        # @param call_block [Dictionary, nil] infers the return type of a
        #   block passed to the call at the call site.
        def initialize api_map, pin, receiver, call_block = nil
          super(api_map, pin, receiver)
          @call_block = call_block
        end

        # @param api_map [ApiMap]
        # @param pin [Pin::Base]
        # @param receiver [Pin::Closure]
        # @param call_block [Dictionary, nil]
        # @return [Typeset]
        def self.expand api_map, pin, receiver, call_block = nil
          new(api_map, pin, receiver, call_block).expand
        end

        def expand
          expanded = pin.typedef_typeset
                        .expand(zip_generic_values)
                        .expand(closure_generic_values)
          block_values = block_return_values(expanded)
          block_values.empty? ? expanded : expanded.expand(block_values)
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

        # Values for method generics supplied by a block passed at the call
        # site. When a method such as Enumerable#map declares its block's
        # return type as a generic (e.g., +Array<generic<U>>+), the value of
        # that generic is determined by the block's inferred return type.
        # Generics already resolved by the receiver (e.g., the element type
        # of Enumerable[String]) are not overwritten.
        #
        # @param typeset [Typeset] the pin's typeset after receiver-based
        #   expansion
        # @return [Hash{String => Object}]
        def block_return_values typeset
          return {} if call_block.nil? || !typeset.generic?
          return {} unless pin.respond_to?(:block) && pin.block
          names = generic_names(pin.block.typedef_typeset) & generic_names(typeset)
          return {} if names.empty?
          inferred = call_block.infer
          return {} if inferred.undefined?
          names.to_h { |name| [name, inferred] }
        end

        # @param node [Typeset, Type, Path, Token]
        # @return [Array<String>]
        def generic_names node
          case node
          when Typeset
            node.types.flat_map { |type| generic_names type }
          when Type
            node.all.flat_map { |part| generic_names part }
          when Token
            node.generic? ? [node.name] : node.params.flat_map { |par| generic_names Typedef.tokenize(par) }
          else
            []
          end
        end

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
