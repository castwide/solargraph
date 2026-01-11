# frozen_string_literal: true

module Solargraph
  module Pin
    class LocalVariable < BaseVariable
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

      def combine_with(other, attrs={})
        # keep this as a parameter
        return other.combine_with(self, attrs) if other.is_a?(Parameter) && !self.is_a?(Parameter)

        super
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
    end
  end
end
