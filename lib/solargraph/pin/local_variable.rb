# frozen_string_literal: true

module Solargraph
  module Pin
    class LocalVariable < BaseVariable
      def combine_with(other, attrs={})
        new_attrs = {
          assignment: assert_same(other, :assignment),
          presence_certain: assert_same(other, :presence_certain?),
          exclude_return_type: combine_types(other, :exclude_return_type),
        }.merge(attrs)
        new_attrs[:presence] = assert_same(other, :presence) unless attrs.key?(:presence)
        new_attrs[:presence_certain] = assert_same(other, :presence_certain) unless attrs.key?(:presence_certain)

        super(other, new_attrs)
      end

      def reset_generated!
        @return_type_minus_exclusions = nil
        super
      end

      # @return [ComplexType, nil]
      def return_type
        @return_type = return_type_minus_exclusions(super)
      end

      # @param raw_return_type [ComplexType, nil]
      # @return [ComplexType, nil]
      def return_type_minus_exclusions(raw_return_type)
        @return_type_minus_exclusions ||=
          if exclude_return_type && raw_return_type
            # @sg-ignore flow sensitive typing needs to handle ivars
            types = raw_return_type.items - exclude_return_type.items
            types = [ComplexType::UniqueType::UNDEFINED] if types.empty?
            ComplexType.new(types)
          else
            raw_return_type
          end
        @return_type_minus_exclusions
      end

      # @param other_closure [Pin::Closure]
      # @param other_loc [Location]
      def visible_at?(other_closure, other_loc)
        # @sg-ignore Need to add nil check here
        location.filename == other_loc.filename &&
          presence.include?(other_loc.range.start) &&
          # @sg-ignore Need to add nil check here
          match_named_closure(other_closure, closure)
      end

      def to_rbs
        (name || '(anon)') + ' ' + (return_type&.to_rbs || 'untyped')
      end

      private

      attr_reader :exclude_return_type
    end
  end
end
