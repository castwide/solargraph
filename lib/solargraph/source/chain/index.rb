# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      # A one-argument 'h[k]' lookup, which a Pin::KeyLookup can prove
      # present, e.g. after 'return unless h.key?(k)'.
      class Index < Call
        # @return [::Array<::Array>, nil] see Pin::KeyLookup#receiver
        attr_reader :receiver_steps

        # @return [::Array<::Array>, nil] see Pin::KeyLookup#key
        attr_reader :key_steps

        # @param receiver [::Parser::AST::Node, nil] the 'h'
        # @param key [::Parser::AST::Node, nil] the 'k'
        # @param location [Location, nil]
        # @param arguments [::Array<Chain>]
        # @param block [Chain, nil]
        def initialize receiver, key, location = nil, arguments = [], block = nil
          super('[]', location, arguments, block)
          @receiver = receiver
          @key = key
          @receiver_steps = Pin::KeyLookup.steps_from_node(receiver)
          @key_steps = Pin::KeyLookup.key_steps_from_node(key)
        end

        # True if a Pin::KeyLookup in `locals` proves this lookup present.
        # Applies only when 'h' is a Hash whose values can't be nil, and 'h'
        # and 'k' read variables or attr_readers, which return the same value
        # every time.
        #
        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param receiver_type [ComplexType, ComplexType::UniqueType] the type of 'h'
        # @param locals [::Array<Pin::LocalVariable, Pin::KeyLookup>]
        # @return [Boolean]
        def present? api_map, name_pin, receiver_type, locals
          location = self.location
          return false if with_block? || arguments.length != 1 || location.nil?
          return false unless receiver_steps && key_steps

          facts = locals.grep(Pin::KeyLookup).select do |fact|
            # @sg-ignore https://github.com/apiology/solargraph/pull/358
            #   also covers: Unresolved call to key on Solargraph::Pin::LocalVariable, Solargraph::Pin::KeyLookup
            fact.visible_at?(name_pin, location) && fact.receiver == receiver_steps && fact.key == key_steps
          end
          return false if facts.empty? || !non_nil_hash?(receiver_type, api_map)

          # the local variables 'h' and 'k' read here
          bindings = []
          return false unless [@receiver, @key].all? { |node| stable?(node, api_map, name_pin, locals, bindings) }

          # @sg-ignore https://github.com/apiology/solargraph/pull/358
          facts.any? { |fact| fact.proves?(api_map, bindings) }
        end

        private

        # @param node [::Parser::AST::Node, nil] a node #steps_from_node accepts
        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param locals [::Array<Pin::LocalVariable, Pin::KeyLookup>]
        # @param bindings [::Array<Pin::LocalVariable>] gets the local
        #   variables `node` reads
        # @return [Boolean] true unless `node` calls a method other than
        #   an attr_reader, or reads a local variable that isn't in sight
        def stable? node, api_map, name_pin, locals, bindings
          return false if node.nil?

          case node.type
          when :lvar
            location = Location.from_node(node)
            return false unless location

            # every same-named variable in sight, as #define merges a block
            # parameter with the outer variable it shadows
            found = locals.grep(Pin::LocalVariable).select do |pin|
              pin.name == node.children[0].to_s && pin.visible_at?(name_pin, location)
            end
            bindings.concat(found)
            !found.empty?
          when :send
            receiver = node.children[0]
            return false unless receiver.nil? ||
                                (receiver.is_a?(::Parser::AST::Node) && stable?(receiver, api_map, name_pin, locals, bindings))

            pins = Parser.chain(node).define(api_map, name_pin, locals)
            !pins.empty? && pins.all? { |pin| pin.is_a?(Pin::Method) && pin.attribute? }
          else
            true
          end
        end

        # @param type [ComplexType, ComplexType::UniqueType]
        # @param api_map [ApiMap]
        # @return [Boolean] true for a Hash whose declared values exclude
        #   nil, e.g. Hash{String => Integer}
        def non_nil_hash? type, api_map
          type.defined? && type.to_a.all? do |t|
            api_map.super_and_sub?('Hash', t.name) &&
              # 'nil' can arrive spelled 'NilClass'
              t.value_types.none? { |value| value.to_a.any? { |u| u.namespace == 'NilClass' } }
          end
        end
      end
    end
  end
end
