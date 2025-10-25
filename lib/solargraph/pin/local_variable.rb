# frozen_string_literal: true

module Solargraph
  module Pin
    class LocalVariable < BaseVariable
      # @return [Range, nil]
      attr_reader :presence

      def presence_certain?
        @presence_certain
      end

      # @param presence [Range, nil]
      # @param presence_certain [Boolean]
      # @param exclude_return_type [ComplexType, nil] Ensure any return
      #   type returned will never include these unique types in the
      #   unique types of its complex type
      # @param splat [Hash]
      def initialize presence: nil, presence_certain: false, exclude_return_type: nil,
                     **splat
        super(**splat)
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
        # keep this as a parameter
        return other.combine_with(self, attrs) if other.is_a?(Parameter) && !self.is_a?(Parameter)

        new_assignments = combine_assignments(other)
        new_attrs = attrs.merge({
          presence: combine_presence(other),
          presence_certain: combine_presence_certain(other),
          exclude_return_type: combine_types(other, :exclude_return_type)
        })
        super(other, new_attrs)
      end

      def inner_desc
        super + ", presence=#{presence.inspect}, presence_certain=#{presence_certain?}"
      end

      # @param other_loc [Location]
      def starts_at?(other_loc)
        location&.filename == other_loc.filename &&
          presence &&
          presence.start == other_loc.range.start
      end

      # @param other [self]
      # @return [Pin::Closure, nil]
      def combine_closure(other)
        return closure if self.closure == other.closure

        # choose first defined, as that establishes the scope of the variable
        if closure.nil? || other.closure.nil?
          Solargraph.assert_or_log(:varible_closure_missing) do
            "One of the local variables being combined is missing a closure: " \
              "#{self.inspect} vs #{other.inspect}"
          end
          return closure || other.closure
        end

        if closure.location.nil? || other.closure.location.nil?
          return closure.location.nil? ? other.closure : closure
        end

        # if filenames are different, this will just pick one
        return closure if closure.location <= other.closure.location

        other.closure
      end

      # @param other_closure [Pin::Closure]
      # @param other_loc [Location]
      def visible_at?(other_closure, other_loc)
        location.filename == other_loc.filename &&
          (!presence || presence.include?(other_loc.range.start)) &&
          visible_in_closure?(other_closure)
      end

      def to_rbs
        (name || '(anon)') + ' ' + (return_type&.to_rbs || 'untyped')
      end

      # @param other [self]
      # @return [ComplexType, nil]
      def combine_return_type(other)
        if presence_certain? && return_type&.defined?
          # flow sensitive typing has already figured out this type
          # has been downcast - use the type it figured out
          return return_type
        end
        if other.presence_certain? && other.return_type&.defined?
          return other.return_type
        end
        combine_types(other, :return_type)
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

      # @param other [self]
      #
      # @return [Array(AST::Node, Integer), nil]
      def combine_mass_assignment(other)
        # @todo pick first non-nil arbitrarily - we don't yet support
        #   mass assignment merging
        mass_assignment || other.mass_assignment
      end

      # Narrow the presence range to the intersection of both.
      #
      # @param other [self]
      #
      # @return [Range, nil]
      def combine_presence(other)
        return presence || other.presence if presence.nil? || other.presence.nil?

        Range.new([presence.start, other.presence.start].max, [presence.ending, other.presence.ending].min)
      end

      # If a certain pin is being combined with an uncertain pin, we
      # end up with a certain result
      #
      # @param other [self]
      #
      # @return [Boolean]
      def combine_presence_certain(other)
        presence_certain? || other.presence_certain?
      end
    end
  end
end
