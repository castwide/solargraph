# frozen_string_literal: true

module Solargraph
  module Pin
    class Reference < Base
      autoload :Require,    'solargraph/pin/reference/require'
      autoload :Superclass, 'solargraph/pin/reference/superclass'
      autoload :Include,    'solargraph/pin/reference/include'
      autoload :Prepend,    'solargraph/pin/reference/prepend'
      autoload :Extend,     'solargraph/pin/reference/extend'
      autoload :Override,   'solargraph/pin/reference/override'

      attr_reader :generic_values

      # @param generic_values [Array<String>]
      def initialize generic_values: [], **splat
        super(**splat)
        @generic_values = generic_values
      end
    end
  end
end
