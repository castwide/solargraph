# frozen_string_literal: true

module Solargraph
  module Pin
    class LocalVariable < BaseVariable
      # @return [Range]
      attr_reader :presence

      # @param presence [Range, nil]
      # @param splat [Hash]
      def initialize presence: nil,
                     **splat
        super(**splat)
        @presence = presence
      end

      # @param api_map [ApiMap]
      # @return [ComplexType]
      def probe api_map
        if presence_certain? && return_type&.defined?
          # flow sensitive typing has already figured out this type
          # has been downcast - use the type it figured out
          return adjust_type api_map, return_type.qualify(api_map, *gates)
        end

        super
      end

      def inner_desc
        super + ", presence=#{presence.inspect}"
      end

      def combine_with(other, attrs={})
        new_attrs = {}.merge(attrs)
        # @sg-ignore Wrong argument type for
        #   Solargraph::Pin::Base#assert_same: other expected
        #   Solargraph::Pin::Base, received self
        new_attrs[:presence] = assert_same(other, :presence) unless attrs.key?(:presence)

        super(other, new_attrs)
      end

      # @param other_closure [Pin::Closure]
      # @param other_loc [Location]
      # @sg-ignore Need to add nil check here
      def visible_at?(other_closure, other_loc)
        # @sg-ignore Need to add nil check here
        location.filename == other_loc.filename &&
          presence&.include?(other_loc.range.start) &&
          # @sg-ignore Need to add nil check here
          match_named_closure(other_closure, closure)
      end

      # @param other_loc [Location]
      def starts_at?(other_loc)
        location&.filename == other_loc.filename &&
          presence &&
          presence.start == other_loc.range.start
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
