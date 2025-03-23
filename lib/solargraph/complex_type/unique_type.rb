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


      # @param generics_to_resolve [Enumerable<String>]
      # @param context_type [UniqueType, nil]
      # @param resolved_generic_values [Hash{String => ComplexType}] Added to as types are encountered or resolved
      # @return [UniqueType, ComplexType]
      def resolve_generics_from_context generics_to_resolve, context_type, resolved_generic_values: {}
        transform(name) do |t|
          next t unless t.name == ComplexType::GENERIC_TAG_NAME

          new_binding = false

          type_param = t.subtypes.first&.name
          next t unless generics_to_resolve.include? type_param
          unless context_type.nil? || !resolved_generic_values[type_param].nil?
            new_binding = true
            resolved_generic_values[type_param] = context_type
          end
          if new_binding
            resolved_generic_values.transform_values! do |complex_type|
              complex_type.resolve_generics_from_context(generics_to_resolve, nil, resolved_generic_values: resolved_generic_values)
            end
          end
          resolved_generic_values[type_param] || t
        end
      end

      # Probe the concrete type for each of the generic type
      # parameters used in this type, and return a new type if
      # possible.
      #
      # @param definitions [Pin::Namespace, Pin::Method] The module/class/method which uses generic types
      # @param context_type [ComplexType] The receiver type
      # @return [UniqueType, ComplexType]
      def resolve_generics definitions, context_type
        return self if definitions.generics.empty?

        transform(name) do |t|
          if t.name == GENERIC_TAG_NAME
            idx = definitions.generics.index(t.subtypes.first&.name)
            next t if idx.nil?
            context_type.all_params[idx] || ComplexType::UNDEFINED
          else
            t
          end
        end
      end

      # @yieldparam t [self]
      # @yieldreturn [self]
      # @return [Array<self>]
      def map &block
        [block.yield(self)]
      end

      # @return [Array<UniqueType>]
      def to_a
        [self]
      end

      # @param new_name [String, nil]
      # @param new_key_types [Array<UniqueType>, nil]
      # @param new_subtypes [Array<UniqueType>, nil]
      # @return [self]
      def recreate(new_name: nil, new_key_types: nil, new_subtypes: nil)
        new_name ||= name
        new_key_types ||= @key_types
        new_subtypes ||= @subtypes
        if new_key_types.none?(&:defined?) && new_subtypes.none?(&:defined?)
          # if all subtypes are undefined, erase down to the non-parametric type
          UniqueType.new(new_name)
        elsif new_key_types.empty? && new_subtypes.empty?
          UniqueType.new(new_name)
        elsif hash_parameters?
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

      # Apply the given transformation to each subtype and then finally to this type
      #
      # @param new_name [String, nil]
      # @yieldparam t [UniqueType]
      # @yieldreturn [self]
      # @return [self]
      def transform(new_name = nil, &transform_type)
        new_key_types = @key_types.flat_map { |ct| ct.map { |ut| ut.transform(&transform_type) } }.compact
        new_subtypes = @subtypes.flat_map { |ct| ct.map { |ut| ut.transform(&transform_type) } }.compact
        new_type = recreate(new_name: new_name || name, new_key_types: new_key_types, new_subtypes: new_subtypes)
        yield new_type
      end

      # Transform references to the 'self' type to the specified concrete namespace
      # @param dst [String]
      # @return [UniqueType]
      def self_to dst
        transform do |t|
          next t if t.name != 'self'
          t.recreate(new_name: dst, new_key_types: [], new_subtypes: [])
        end
      end

      def selfy?
        @name == 'self' || @key_types.any?(&:selfy?) || @subtypes.any?(&:selfy?)
      end

      UNDEFINED = UniqueType.new('undefined')
      BOOLEAN = UniqueType.new('Boolean')
    end
  end
end
