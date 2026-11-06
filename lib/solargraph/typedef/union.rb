# frozen_string_literal: true

module Solargraph
  module Typedef
    # A union: any one member describes the value.
    class Union < Typeset
      def nullable?
        types.any?(&:nullable?)
      end

      def to_s
        types.join(' | ')
      end

      # Pairs this union up with another type member by member, yields
      # each pair, and reassembles the results into one union.
      #
      # @param other [Type]
      # @yieldparam mine [Type]
      # @yieldparam theirs [Type]
      # @yieldreturn [Type]
      # @return [Union]
      def combine_via(other, &)
        theirs = other.is_a?(Union) ? other.types : [other]
        # @param members [Array<Type>]
        gather = ->(members) { members.length == 1 ? members.fetch(0) : Union.new(members) }
        key = lambda(&:to_s)
        Union.new(Pairing.combine_members(types, theirs, gather, key, &))
      end

      # Moves nil members to the end by convention; the other members keep
      # their order.
      #
      # @return [Union]
      def order_nil_last
        nils, rest = types.partition(&:nullable?)
        Union.new(rest + nils)
      end

      def to_s_for_complex_type
        types.map(&:to_s_for_complex_type).join(', ').to_s
      end

      # The method stacks for +method_name+ of each member, concatenated,
      # so precedence orders each member's run; empty when a member does
      # not resolve it and ApiMap#loose_unions is off.
      #
      # @param api_map [ApiMap]
      # @param method_name [String]
      # @return [Array<Pin::Method>]
      def reachable_method_stack api_map, method_name
        stacks = types.map { |type| type.reachable_method_stack(api_map, method_name) }
        return [] if !api_map.loose_unions && stacks.any?(&:empty?)

        # @param pin [Pin::Base]
        stacks.flatten.uniq { |pin| [pin.path, pin.return_type.rooted_tags] }
      end

      # The union of what a call to +word+ returns on each member that
      # resolves it; undefined if the call is undefined on any of them.
      # Undefined, without yielding, when no member resolves +word+, or
      # when one does not and ApiMap#loose_unions is off.
      #
      # @param word [String]
      # @param api_map [ApiMap]
      # @yieldparam receiver [Concrete]
      # @yieldparam pins [Array<Pin::Base>]
      # @yieldreturn [Type]
      # @return [Type]
      def call_type word, api_map, &block
        resolving = types.reject { |type| type.reachable_method_stack(api_map, word).empty? }
        return UNDEFINED if resolving.empty?
        return UNDEFINED if !api_map.loose_unions && resolving.length < types.length

        results = resolving.map { |type| type.call_type(word, api_map, &block) }
        return UNDEFINED if results.any?(&:undefined?)

        Union.new(results).order_nil_last
      end

      # @return [ComplexType]
      def to_complex_type
        ComplexType.new(types.map(&:to_complex_type))
      end

      UNDEFINED = Union.new([Concrete::UNDEFINED])
    end
  end
end
