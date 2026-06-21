# frozen_string_literal: true

module Solargraph
  module Typedef
    class Typeset
      attr_reader :types

      # @param types [Array<Typeset, Type>]
      def initialize types
        # @todo Slightly naive reduction of nested typesets to types
        @types = types.flat_map do |type_or_set|
          if type_or_set.is_a?(Typeset)
            type_or_set.types
          elsif type_or_set.is_a?(Type) && type_or_set.base.is_a?(Typeset) && type_or_set.params.empty?
            type_or_set.base.types
          else
            type_or_set
          end
        end
        reduce!
      end

      # @param named_values [Hash]
      def expand(named_values)
        Typeset.new(types.map { |type| type.expand(named_values) })
      end

      # @param typeset [Typeset, nil]
      def extract_generics(typeset)
        return {} unless generic? && typeset.is_a?(Typeset)
        extracted = {}
        types.each.with_index { |type, idx| extracted.merge! type.extract_generics(typeset.types[idx]) }
        extracted
      end

      def resolve_rooted(api_map, gates)
        Typeset.new(types.map { |type| type.resolve_rooted(api_map, gates) })
      end

      def generic?
        types.any?(&:generic?)
      end

      def rooted?
        types.all?(&:rooted?)
      end

      # @return [ComplexType]
      def to_complex_type
        ComplexType.new(types.map(&:to_complex_type))
      end

      def flat_types
        types.flat_map(&:flat_types)
      end

      def nullable?
        types.any?(&:nullable?)
      end

      def to_s
        types.join(' | ')
      end

      def to_s_for_complex_type
        "#{types.map(&:to_s_for_complex_type).join(', ')}"
      end

      private

      def reduce!
        types.uniq!(&:to_s)
      end

      UNDEFINED = Typeset.new([Type::UNDEFINED])
    end
  end
end
