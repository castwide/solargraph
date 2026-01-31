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

      # A Reference is a pin that associates a type with another type.
      # The existing type is marked as the closure.  The name of the
      # type we're associating with it is the 'name' field, and
      # subtypes are in the 'generic_values' field.
      #
      # These pins are a little different - the name is a rooted name,
      # which may be relative or absolute, preceded with ::, not a
      # fully qualified namespace, which is implicitly in the root
      # namespace and is never preceded by ::.
      #
      # @todo can the above be represented in a less subtle way?
      # @todo consider refactoring so that we can replicate more
      # complex types like Hash{String => Integer} and has both key
      # types and subtypes.
      #
      # @param name [String] rooted name of the referenced type
      # @param generic_values [Array<String>]
      # @param [Hash{Symbol => Object}] splat
      def initialize generic_values: [], **splat
        super(**splat)
        @generic_values = generic_values
      end

      # @return [ComplexType]
      def type
        @type ||= ComplexType.try_parse(
          name +
          if generic_values&.length&.> 0
            "<#{generic_values.join(', ')}>"
          else
            ''
          end
        )
      end

      # @sg-ignore Need to add nil check here
      # @return [Array<String>]
      def reference_gates
        # @sg-ignore Need to add nil check here
        closure.gates
      end
    end
  end
end
