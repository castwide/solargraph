# frozen_string_literal: true

module Solargraph
  module Pin
    class LocalVariable < BaseVariable
      def combine_with(other, attrs={})
        # keep this as a parameter
        return other.combine_with(self, attrs) if other.is_a?(Parameter) && !self.is_a?(Parameter)

        super
      end

      def to_rbs
        (name || '(anon)') + ' ' + (return_type&.to_rbs || 'untyped')
      end
    end
  end
end
