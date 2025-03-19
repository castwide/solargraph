# frozen_string_literal: true

module Solargraph
  class ComplexType
    # An individual type signature. A complex type can consist of multiple
    # unique types.
    #
    class UniqueType
      include TypeMethods

      attr_reader :all_params

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
        # @type [Array<ComplexType>]
        @key_types = []
        # @type [Array<ComplexType>]
        @subtypes = []
        # @type [Array<ComplexType>]
        @all_params = []
        return unless parameters?
        # @todo we should be able to probe the type of 'subs' without
        #   hoisting the definition outside of the if statement
        subs = if @substring.start_with?('<(') && @substring.end_with?(')>')
                 ComplexType.parse(substring[2..-3], partial: true)
               else
                 ComplexType.parse(substring[1..-2], partial: true)
               end
        if hash_parameters?
          raise ComplexTypeError, "Bad hash type" unless !subs.is_a?(ComplexType) and subs.length == 2 and !subs[0].is_a?(UniqueType) and !subs[1].is_a?(UniqueType)
          # @todo should be able to resolve map; both types have it
          #   with same return type
          # @sg-ignore
          @key_types.concat subs[0].map { |u| ComplexType.new([u]) }
          # @sg-ignore
          @subtypes.concat subs[1].map { |u| ComplexType.new([u]) }
        else
          @subtypes.concat subs
        end
        @all_params.concat @key_types
        @all_params.concat @subtypes
      end

      def to_s
        tag
      end

      # @return [Array<UniqueType>]
      def items
        [self]
      end

      # @return [String]
      def to_rbs
        "#{namespace}#{parameters? ? "[#{subtypes.map { |s| s.to_rbs }.join(', ')}]" : ''}"
      # "
      end

      def generic?
        name == GENERIC_TAG_NAME || all_params.any?(&:generic?)
      end


      # Probe the concrete type for each of the generic type
      # parameters used in this type, and return a new type if
      # possible.
      #
      # @param definitions [Pin::Namespace, Pin::Method] The module/class/method which uses generic types
      # @param context_type [ComplexType] The receiver type
      # @return [UniqueType, ComplexType]
      def resolve_generics definitions, context_type
        if name == GENERIC_TAG_NAME
          idx = definitions.generics.index(subtypes.first&.name)
          return ComplexType::UNDEFINED if idx.nil?
          param_type = context_type.all_params[idx]
          return ComplexType::UNDEFINED unless param_type
          new_name = param_type.to_s
        end
        return UniqueType.new(new_name) if name == GENERIC_TAG_NAME
        transform(name) do |t|
          new_type = t.resolve_generics(definitions, context_type)
          new_type if new_type.defined?
        end
      end

      # @param new_name [String]
      # @yieldparam t [ComplexType]
      # @yieldreturn [ComplexType]
      # @return [UniqueType, nil]
      def transform(new_name, &transform_type)
        new_key_types = @key_types.map { |t| transform_type.yield t }.compact
        new_subtypes = @subtypes.map { |t| transform_type.yield t }.compact

        return UniqueType.new(new_name) if new_key_types.empty? && new_subtypes.empty?

        if hash_parameters?
          UniqueType.new(new_name, "{#{new_key_types.join(', ')} => #{new_subtypes.join(', ')}}")
        elsif @substring.start_with?('<(')
          # @todo This clause is probably wrong, and if so, fixing it
          #    will be some level of breaking change.  Probably best
          #    handled before real tuple support is rolled out and
          #    folks start relying on it more.
          #
          #   (String) is a one element tuple in https://yardoc.org/types
          #   <String> is an array of zero or more Strings in https://yardoc.org/types
          #   Array<(String)> could be an Array of one-element tuples or a
          #     one element tuple.  https://yardoc.org/types treats it
          #     as the former.
          #   Array<(String), Integer> is not ambiguous if we accept
          #     (String) as a tuple type, but not currently understood
          #     by Solargraph.
          UniqueType.new(new_name, "<(#{new_subtypes.join(', ')})>")
        elsif fixed_parameters?
          UniqueType.new(new_name, "(#{new_subtypes.join(', ')})")
        else
          UniqueType.new(new_name, "<#{new_subtypes.join(', ')}>")
        end
      end

      # Transform references to the 'self' type to the specified concrete namespace
      # @param dst [String]
      # @return [UniqueType]
      def self_to dst
        return self unless selfy?
        new_name = (@name == 'self' ? dst : @name)
        transform(new_name) { |t| t.self_to dst }
      end

      def selfy?
        @name == 'self' || @key_types.any?(&:selfy?) || @subtypes.any?(&:selfy?)
      end

      UNDEFINED = UniqueType.new('undefined')
      BOOLEAN = UniqueType.new('Boolean')
    end
  end
end
