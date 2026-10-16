# frozen_string_literal: true

module Solargraph
  module Pin
    class InstanceVariable < BaseVariable
      # @sg-ignore Need to add nil check here
      # @return [ComplexType, ComplexType::UniqueType]
      def binder
        # @sg-ignore Need to add nil check here
        closure.binder
      end

      # @sg-ignore Need to add nil check here
      # @return [::Symbol]
      def scope
        # @sg-ignore Need to add nil check here
        closure.binder.scope
      end

      # @return [ComplexType]
      def context
        @context ||= begin
          result = super
          if scope == :class
            ComplexType.parse("::Class<#{result.rooted_namespace}>")
          else
            result.reduce_class_type
          end
        end
      end

      # @param other [InstanceVariable]
      def nearly? other
        super && binder == other.binder
      end

      # Unlike a local's, an ivar assignment has no presence to hide it
      # from reads before it, so also require it to start before
      # `location`.
      #
      # @param location [Location, nil]
      # @return [Boolean]
      def definite_reaches? location
        start = self.location&.range&.start
        return false unless super && start

        # @sg-ignore flow sensitive typing needs to handle attrs
        (location.range.start <=> start) == 1
      end

      # True if a read at `location` from `viewing_closure` sees only
      # this assignment's value, not the ivar's other assignments: it
      # dominates the read within the same method, and isn't derived
      # from the previous value (`@x = @x.foo`).  Calls in between
      # are assumed not to reassign the ivar.
      #
      # @param viewing_closure [Pin::Closure]
      # @param location [Location]
      # @return [Boolean]
      def dominates? viewing_closure, location
        definite_reaches?(location) && within_closure?(viewing_closure) &&
          value_nodes.none? { |node| references_name?(node) }
      end
    end
  end
end
