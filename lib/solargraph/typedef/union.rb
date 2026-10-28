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

      # Pins for calling +word+ on each member, or nil when a member does
      # not resolve it and ApiMap#loose_unions is off.
      #
      # @param word [String]
      # @param api_map [ApiMap]
      # @return [Array<Pin::Base>, nil]
      def method_stack_pins word, api_map
        pin_groups = types.map { |type| type.method_stack_pins(word, api_map) }
        return nil if !api_map.loose_unions && pin_groups.any?(&:nil?)

        found = pin_groups.compact
        return nil if found.empty?

        # @param pin [Pin::Base]
        found.flatten.uniq { |pin| [pin.path, pin.return_type.rooted_tags] }
      end

      # @return [ComplexType]
      def to_complex_type
        ComplexType.new(types.map(&:to_complex_type))
      end

      UNDEFINED = Union.new([Concrete::UNDEFINED])
    end
  end
end
