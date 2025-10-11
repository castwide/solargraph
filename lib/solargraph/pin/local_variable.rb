# frozen_string_literal: true

module Solargraph
  module Pin
    class LocalVariable < BaseVariable
      # @return [Range]
      attr_reader :presence

      def presence_certain?
        @presence_certain
      end

      # @param assignment [AST::Node, nil]
      # @param presence [Range, nil]
      # @param presence_certain [Boolean]
      # @param exclude_return_type [ComplexType, nil] Ensure any return
      #   type returned will never include these unique types in the
      #   unique types of its complex type
      # @param splat [Hash]
      def initialize assignment: nil, presence: nil, presence_certain: false, exclude_return_type: nil,
                     **splat
        super(**splat)
        @assignment = assignment
        @presence = presence
        @presence_certain = presence_certain
        @exclude_return_type = exclude_return_type
      end

      def reset_generated!
        @return_type_minus_exclusions = nil
        super
      end

      # @return [ComplexType, nil]
      def return_type
        return_type_minus_exclusions(@return_type || generate_complex_type)
      end

      # @param raw_return_type [ComplexType, nil]
      # @return [ComplexType, nil]
      def return_type_minus_exclusions(raw_return_type)
        @return_type_minus_exclusions ||=
          if exclude_return_type && raw_return_type
            types = raw_return_type.items - exclude_return_type.items
            types = [ComplexType::UniqueType::UNDEFINED] if types.empty?
            ComplexType.new(types)
          else
            raw_return_type
          end
      end

      # @param api_map [ApiMap]
      # @return [ComplexType]
      def probe api_map
        if presence_certain? && return_type&.defined?
          # flow sensitive typing has already figured out this type
          # has been downcast - use the type it figured out
          return return_type.qualify(api_map, *gates)
        end

        super
      end

      def combine_with(other, attrs={})
        new_attrs = {
          assignment: assert_same(other, :assignment),
          presence_certain: assert_same(other, :presence_certain?),
        }.merge(attrs)
        # @sg-ignore Wrong argument type for
        #   Solargraph::Pin::Base#assert_same: other expected
        #   Solargraph::Pin::Base, received self
        new_attrs[:presence] = assert_same(other, :presence) unless attrs.key?(:presence)

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

      attr_reader :exclude_return_type

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
