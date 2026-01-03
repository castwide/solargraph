# frozen_string_literal: true

module Solargraph
  module Pin
    class LocalVariable < BaseVariable
      # @param api_map [ApiMap]
      # @return [ComplexType, ComplexType::UniqueType]
      def probe api_map
        if presence_certain? && return_type && return_type&.defined?
          # flow sensitive typing has already figured out this type
          # has been downcast - use the type it figured out
          # @sg-ignore Flow-sensitive typing should support ivars
          return adjust_type api_map, return_type.qualify(api_map, *gates)
        end

        super
      end

      def combine_with(other, attrs={})
        # keep this as a parameter
        return other.combine_with(self, attrs) if other.is_a?(Parameter) && !self.is_a?(Parameter)

        super
      end

      # @sg-ignore Flow-sensitive typing should support ivars
      # @param other_loc [Location]
      def starts_at?(other_loc)
        location&.filename == other_loc.filename &&
          presence &&
          # @sg-ignore Flow-sensitive typing should support ivars
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

        # @sg-ignore Flow-sensitive typing should support ivars
        if closure.location.nil? || other.closure.location.nil?
          # @sg-ignore Flow-sensitive typing should support ivars
          return closure.location.nil? ? other.closure : closure
        end

        # if filenames are different, this will just pick one
        # @sg-ignore Flow-sensitive typing should support ivars
        return closure if closure.location <= other.closure.location

        other.closure
      end

      # @param other_closure [Pin::Closure]
      # @param other_loc [Location]
      def visible_at?(other_closure, other_loc)
        # @sg-ignore Need to add nil check here
        location.filename == other_loc.filename &&
          # @sg-ignore Flow-sensitive typing should support ||
          (!presence || presence.include?(other_loc.range.start)) &&
          visible_in_closure?(other_closure)
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
    end
  end
end
