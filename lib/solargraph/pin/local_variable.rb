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

      def to_rbs
        (name || '(anon)') + ' ' + (return_type&.to_rbs || 'untyped')
      end

      private

      attr_reader :exclude_return_type
    end
  end
end
