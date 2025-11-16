# frozen_string_literal: true

module Solargraph
  module Pin
    class LocalVariable < BaseVariable
      # @return [Range, nil]
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
        # keep this as a parameter
        return other.combine_with(self, attrs) if other.is_a?(Parameter) && !self.is_a?(Parameter)

        new_attrs = attrs.merge({
          presence: combine_presence(other),
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
      # @sg-ignore Need to add nil check here
      def visible_at?(other_closure, other_loc)
        # @sg-ignore Need to add nil check here
        location.filename == other_loc.filename &&
          (!presence || presence.include?(other_loc.range.start)) &&
          visible_in_closure?(other_closure)
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
