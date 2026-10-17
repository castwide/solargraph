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

      def to_s_for_complex_type
        types.map(&:to_s_for_complex_type).join(', ').to_s
      end

      # @return [ComplexType]
      def to_complex_type
        ComplexType.new(types.map(&:to_complex_type))
      end

      UNDEFINED = Union.new([Concrete::UNDEFINED])
    end
  end
end
