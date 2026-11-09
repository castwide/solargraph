# frozen_string_literal: true

module Solargraph
  module Typedef
    module Expansions
      # Contextual expansion of generic tokens
      #
      class Generics < Base
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
            positional = if type
                           closure_names.map { |name| "generic<#{name}>" }.zip(type.params).to_h
                         else
                           {}
                         end
            positional.merge(receiver_namespace_generic_values) { |_name, existing, _by_name| existing }
          end
        end

        private

        # Generic values for the type parameters of the receiver's own
        # namespaces, matched by name rather than by position.
        #
        # Methods reached through included modules and interfaces carry the
        # generics of the namespace that declares them. RBS, for example,
        # defines +Enumerable[E]+ as +Enumerable[E] < _Each[E]+, so the +each+
        # pin of an +Enumerable[String]+ receiver comes from +_Each+ and names
        # its block parameter +generic<E>+. Such a generic cannot be derived by
        # zipping positions, since the declaring namespace's parameters rarely
        # line up with the receiver's, so every flat type in the receiver binds
        # its own namespace's parameters by name.
        #
        # @return [Hash{String => Object}]
        def receiver_namespace_generic_values
          return {} if receiver.nil?
          typeset = receiver.typedef_typeset
          return {} if typeset.nil?
          values = {}
          typeset.flat_types.each do |type|
            next if type.params.empty?
            namespace_pin = api_map.get_path_pins(type.base.to_s).grep(Pin::Namespace).first
            next if namespace_pin.nil?
            namespace_pin.generics.each_with_index do |name, index|
              param = type.params[index]
              next if param.nil?
              values["generic<#{name}>"] ||= param
            end
          end
          values
        end

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
          return {} unless typeset.generic? && receiver.closure.is_a?(Pin::Block)
          # return {} unless pin.respond_to?(:block) && pin.block
          names = generic_names(pin.block.typedef_typeset) & generic_names(typeset)
          return {} if names.empty?
          return {} unless receiver.closure.is_a?(Pin::Block)

          chain = Parser::ParserGem::NodeChainer.chain(receiver.closure.node)
          dictionary = Dictionary.new(api_map, receiver.closure.filename, chain.links.last.block)
          inferred = dictionary.infer
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
