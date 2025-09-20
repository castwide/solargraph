# frozen_string_literal: true

module Solargraph
  module Pin
    class LocalVariable < BaseVariable
      # @return [Range]
      attr_reader :presence

      # @return [Boolean]
      attr_reader :presence_certain

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
      def initialize assignment: nil, presence: nil, presence_certain: false,
                     exclude_return_type: nil, **splat
        super(**splat)
        @assignment = assignment
        @presence = presence
        @presence_certain = presence_certain
        @exclude_return_type = exclude_return_type
      end

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

      # @param other [self]
      # @param attr [::Symbol]
      #
      # @return [ComplexType, nil]
      def combine_types(other, attr)
        # @type [ComplexType, nil]
        type1 = send(attr)
        # @type [ComplexType, nil]
        type2 = other.send(attr)
        if type1 && type2
          types = (type1.items + type2.items).uniq
          ComplexType.new(types)
        else
          type1 || type2
        end
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
            # @sg-ignore flow sensitive typing needs to handle && on both sides
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
          # @sg-ignore Need to add nil check here
          cursor = cursor.closure
        end
        false
      end
    end
  end
end
