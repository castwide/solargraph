# frozen_string_literal: true

module Solargraph
  module Pin
    class LocalVariable < BaseVariable
      def to_rbs
        (name || '(anon)') + ' ' + (return_type&.to_rbs || 'untyped')
      end
    end
  end
end
