module Solargraph
  class ComplexType
    # An individual type signature. A complex type can consist of multiple
    # unique types.
    #
    class UniqueType
      include TypeMethods

      # Create a UniqueType with the specified name and an optional substring.
      # The substring is the parameter section of a parametrized type, e.g.,
      # for the type `Array<String>`, the name is `Array` and the substring is
      # `<String>`.
      #
      # @param name [String] The name of the type
      # @param substring [String] The substring of the type
      def initialize name, substring = ''
        if name.start_with?('::')
          @name = name[2..-1]
          @rooted = true
        else
          @name = name
          @rooted = false
        end
        @substring = substring
        @tag = @name + substring
        @key_types = []
        @subtypes = []
        return unless parameters?
        subs = ComplexType.parse(substring[1..-2], partial: true)
        if hash_parameters?
          raise ComplexTypeError, "Bad hash type" unless !subs.is_a?(ComplexType) and subs.length == 2 and !subs[0].is_a?(UniqueType) and !subs[1].is_a?(UniqueType)
          @key_types.concat subs[0].map { |u| ComplexType.new([u]) }
          @subtypes.concat subs[1].map { |u| ComplexType.new([u]) }
        else
          @subtypes.concat subs
        end
      end

      def to_s
        tag
      end

      UNDEFINED = UniqueType.new('undefined')
    end
  end
end
