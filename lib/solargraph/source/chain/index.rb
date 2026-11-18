# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      # A one-argument 'h[k]' lookup, which a Pin::ExpressionNarrowing
      # can prove present, e.g. after 'return unless h.key?(k)'.
      class Index < Call
        # @return [::Array<::Array>, nil] see Pin::ExpressionNarrowing#steps
        attr_reader :steps

        # @param node [::Parser::AST::Node] the 'h[k]'
        # @param location [Location, nil]
        # @param arguments [::Array<Chain>]
        # @param block [Chain, nil]
        def initialize node, location = nil, arguments = [], block = nil
          super('[]', location, arguments, block)
          @receiver, _, @key = node.children
          @steps = Pin::ExpressionNarrowing.steps_from_node(node)
        end

        # The Pin::ExpressionNarrowing in `locals` that proves this lookup
        # present, if any. Applies only when 'h' is a Hash whose values
        # can't be nil, and 'h' and 'k' read variables or attr_readers,
        # which return the same value every time.
        #
        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param receiver_type [ComplexType, ComplexType::UniqueType] the type of 'h'
        # @param locals [::Array<Pin::Narrowing>] variables and expression narrowings visible at this point
        # @sg-ignore Declared return type ::Solargraph::Pin::ExpressionNarrowing, nil does not match inferred type ::Solargraph::Pin::Narrowing, nil for Solargraph::Source::Chain::Index#narrowing
        # @return [Pin::ExpressionNarrowing, nil]
        def narrowing api_map, name_pin, receiver_type, locals
          location = self.location
          return if with_block? || arguments.length != 1 || location.nil? || steps.nil?

          facts = locals.grep(Pin::ExpressionNarrowing).select do |fact|
            # @sg-ignore Unresolved call to steps on Solargraph::Pin::Narrowing
            fact.visible_at?(name_pin, location) && fact.steps == steps
          end
          return if facts.empty? || !non_nil_hash?(receiver_type, api_map)

          # the local variables 'h' and 'k' read here
          bindings = []
          return unless [@receiver, @key].all? { |node| stable?(node, api_map, name_pin, locals, bindings) }

          # @sg-ignore Unresolved call to proves? on Solargraph::Pin::Narrowing
          facts.find { |fact| fact.proves?(api_map, bindings) }
        end

        private

        # @param node [::Parser::AST::Node, nil] a node #steps_from_node accepts
        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param locals [::Array<Pin::Narrowing>] variables and expression narrowings visible at this point
        # @param bindings [::Array<Pin::BaseVariable>] gets the local
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
            found = Pin::Narrowing.variables(locals).select do |pin|
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
