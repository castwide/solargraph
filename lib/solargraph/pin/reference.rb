# frozen_string_literal: true

module Solargraph
  module Pin
    class Reference < Base
      autoload :Require,    'solargraph/pin/reference/require'
      autoload :Superclass, 'solargraph/pin/reference/superclass'
      autoload :Include,    'solargraph/pin/reference/include'
      autoload :Prepend,    'solargraph/pin/reference/prepend'
      autoload :Extend,     'solargraph/pin/reference/extend'
      autoload :IncludedMixin, 'solargraph/pin/reference/included_mixin'
      autoload :Override,   'solargraph/pin/reference/override'
      autoload :TypeAlias,  'solargraph/pin/reference/type_alias'

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
      # @param generic_values [Array<ComplexType>]
      # @param [Hash{Symbol => Object}] splat
      def initialize generic_values: [], **splat
        super(**splat)
        @generic_values = generic_values
      end

      # @return [ComplexType]
      def type
        @type ||= ComplexType.new([referenced_type])
      end

      # @sg-ignore Need to add nil check here
      # @return [Array<String>]
      def reference_gates
        # @sg-ignore Need to add nil check here
        closure.gates
      end

      private

      # @return [ComplexType::UniqueType]
      def referenced_type
        base = name.delete_prefix('::')
        rooted = name.start_with?('::') || !ComplexType::UniqueType.can_root_name?(base)
        return ComplexType::UniqueType.new(base, rooted: rooted) if generic_values.empty?

        # As in a parsed Hash<K, V>, two values on a Hash are its key and value
        key_types, subtypes = if base == 'Hash' && generic_values.length == 2
                                [[generic_values.first], [generic_values.last]]
                              else
                                [[], generic_values]
                              end
        ComplexType::UniqueType.new(base, key_types, subtypes, rooted: rooted, parameters_type: :list)
      end
    end
  end
end
