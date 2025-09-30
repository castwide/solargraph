# frozen_string_literal: true

module Solargraph
  module Pin
    class LocalVariable < BaseVariable
      # @return [Range]
      attr_reader :presence

      def presence_certain?
        @presence_certain
      end

      # @param presence [Range, nil]
      # @param presence_certain [Boolean]
      # @param splat [Hash]
      def initialize presence: nil, presence_certain: false, **splat
        super(**splat)
        @presence = presence
        @presence_certain = presence_certain
      end

      def combine_with(other, attrs={})
        new_attrs = {
          # @sg-ignore https://github.com/castwide/solargraph/pull/1050
          presence_certain: assert_same(other, :presence_certain?),
        }.merge(attrs)
        # @sg-ignore https://github.com/castwide/solargraph/pull/1050
        new_attrs[:presence] = assert_same(other, :presence) unless attrs.key?(:presence)

        # @sg-ignore https://github.com/castwide/solargraph/pull/1050
        super(other, new_attrs)
      end

      # @param other_closure [Pin::Closure]
      # @param other_loc [Location]
      def visible_at?(other_closure, other_loc)
        location.filename == other_loc.filename &&
          presence.include?(other_loc.range.start) &&
          match_named_closure(other_closure, closure)
      end

      def to_rbs
        (name || '(anon)') + ' ' + (return_type&.to_rbs || 'untyped')
      end

      private

      # @param tag1 [String]
      # @param tag2 [String]
      # @return [Boolean]
      def match_tags tag1, tag2
        # @todo This is an unfortunate hack made necessary by a discrepancy in
        #   how tags indicate the root namespace. The long-term solution is to
        #   standardize it, whether it's `Class<>`, an empty string, or
        #   something else.
        tag1 == tag2 ||
          (['', 'Class<>'].include?(tag1) && ['', 'Class<>'].include?(tag2))
      end

      # @param needle [Pin::Base]
      # @param haystack [Pin::Base]
      # @return [Boolean]
      def match_named_closure needle, haystack
        return true if needle == haystack || haystack.is_a?(Pin::Block)
        cursor = haystack
        until cursor.nil?
          return true if needle.path == cursor.path
          return false if cursor.path && !cursor.path.empty?
          cursor = cursor.closure
        end
        false
      end
    end
  end
end
