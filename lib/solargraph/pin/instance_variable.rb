# frozen_string_literal: true

module Solargraph
  module Pin
    class InstanceVariable < BaseVariable
      include ClosureRequired

      # @return [ComplexType, ComplexType::UniqueType]
      def binder
        closure.binder
      end

      # @return [::Symbol]
      def scope
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

      # Same-file requirement only applies when +presence+ is set; an
      # unnarrowed ivar has none and can be assigned and read in
      # different files (e.g. ancestor class's method vs. descendant's).
      #
      # @param other_closure [Pin::Closure]
      # @param other_loc [Location]
      def visible_at? other_closure, other_loc
        return false if presence && location&.filename != other_loc.filename
        # @sg-ignore flow sensitive typing needs to handle attrs
        return false if presence && !presence.include?(other_loc.range.start)

        visible_in_closure?(other_closure)
      end

      private

      # Unlike BaseVariable, doesn't stop at a lexically-mismatched
      # Namespace pin: #get_instance_variable_pins already restricts
      # candidates to the reading namespace and its ancestors, so
      # reaching one here means visible via inheritance.
      #
      # @param viewing_closure [Pin::Closure]
      # @return [Boolean]
      def visible_in_closure? viewing_closure
        return false if closure.nil?

        # top-level ivars aren't visible from within a method
        return false if viewing_closure.is_a?(Pin::Method) && closure.context.tags == 'Class<>'

        return true if viewing_closure.binder.namespace == closure.binder.namespace

        return true if viewing_closure.return_type == closure.context

        return true if viewing_closure.is_a?(Pin::Namespace)

        parent_of_viewing_closure = viewing_closure.closure

        return false if parent_of_viewing_closure.nil?

        visible_in_closure?(parent_of_viewing_closure)
      end
    end
  end
end
