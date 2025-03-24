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
      # @param make_rooted [Boolean, nil]
      # @return [UniqueType]
      def self.parse name, substring = '', make_rooted: nil
        if name.start_with?(':::')
          raise "Illegal prefix: #{name}"
        end
        if name.start_with?('::')
          name = name[2..-1]
          rooted = true
        else
          rooted = false
        end
        rooted = make_rooted unless make_rooted.nil?

        # @type [Array<ComplexType>]
        key_types = []
        # @type [Array<ComplexType>]
        subtypes = []
        parameters_type = nil
        unless substring.empty?
          subs = ComplexType.parse(substring[1..-2], partial: true)
          parameters_type = PARAMETERS_TYPE_BY_STARTING_TAG.fetch(substring[0])
          if parameters_type == :hash
            raise ComplexTypeError, "Bad hash type" unless !subs.is_a?(ComplexType) and subs.length == 2 and !subs[0].is_a?(UniqueType) and !subs[1].is_a?(UniqueType)
            # @todo should be able to resolve map; both types have it
            #   with same return type
            # @sg-ignore
            key_types.concat(subs[0].map { |u| ComplexType.new([u]) })
            # @sg-ignore
            subtypes.concat(subs[1].map { |u| ComplexType.new([u]) })
          else
            subtypes.concat subs
          end
        end
        new(name, key_types, subtypes, rooted: rooted, parameters_type: parameters_type)
      end

      # @param name [String]
      # @param key_types [Array<ComplexType>]
      # @param subtypes [Array<ComplexType>]
      # @param rooted [Boolean]
      # @param parameters_type [Symbol, nil]
      def initialize(name, key_types = [], subtypes = [], rooted:, parameters_type: nil)
        if parameters_type.nil?
          raise "You must supply parameters_type if you provide parameters" unless key_types.empty? && subtypes.empty?
        end
        raise "Please remove leading :: and set rooted instead - #{name}" if name.start_with?('::')
        @name = name
        @key_types = key_types
        @subtypes = subtypes
        @rooted = rooted
        @all_params = []
        @all_params.concat key_types
        @all_params.concat subtypes
        @parameters_type = parameters_type
      end

      def to_s
        tag
      end

      # @return [Array<UniqueType>]
      def items
        [self]
      end

      # @return [String]
      def rbs_name
        if name == 'undefined'
          'untyped'
        else
          rooted_name
        end
      end

      # @return [String]
      def to_rbs
        if duck_type?
          'untyped'
        elsif name == 'Boolean'
          'bool'
        elsif name.downcase == 'nil'
          'nil'
        elsif name == GENERIC_TAG_NAME
          all_params.first.name
        elsif ['Class', 'Module'].include?(name)
          rbs_name
        elsif ['Tuple', 'Array'].include?(name) && fixed_parameters?
          # tuples don't have a name; they're just [foo, bar, baz].
          if substring == '()'
            # but there are no zero element tuples, so we go with an array
            'Array[]'
          else
            # already generated surrounded by []
            parameters_as_rbs
          end
        else
          "#{rbs_name}#{parameters_as_rbs}"
        end
      end

      # @return [Boolean]
      def parameters?
        !all_params.empty?
      end

      # @param types [Array<UniqueType, ComplexType>]
      # @return [String]
      def rbs_union(types)
        if types.length == 1
          types.first.to_rbs
        else
          "(#{types.map(&:to_rbs).join(' | ')})"
        end
      end

      # @return [String]
      def parameters_as_rbs
        return '' unless parameters?

        return "[#{all_params.map(&:to_rbs).join(', ')}]" if key_types.empty?

        # handle, e.g., Hash[K, V] case
        key_types_str = rbs_union(key_types)
        subtypes_str = rbs_union(subtypes)
        "[#{key_types_str}, #{subtypes_str}]"
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
        return self if definitions.nil? || definitions.generics.empty?

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
      # @param make_rooted [Boolean, nil]
      # @param new_key_types [Array<UniqueType>, nil]
      # @param rooted [Boolean, nil]
      # @param new_subtypes [Array<UniqueType>, nil]
      # @return [self]
      def recreate(new_name: nil, make_rooted: nil, new_key_types: nil, new_subtypes: nil)
        raise "Please remove leading :: and set rooted instead - #{new_name}" if new_name.start_with?('::')
        new_name ||= name
        new_key_types ||= @key_types
        new_subtypes ||= @subtypes
        make_rooted = @rooted if make_rooted.nil?
        UniqueType.new(new_name, new_key_types, new_subtypes, rooted: make_rooted, parameters_type: parameters_type)
      end

      # @return [String]
      def rooted_tags
        rooted_tag
      end

      # @return [String]
      def tags
        tag
      end

      # @return [self]
      def force_rooted
        transform do |t|
          t.recreate(make_rooted: true)
        end
      end

      # Apply the given transformation to each subtype and then finally to this type
      #
      # @param new_name [String, nil]
      # @yieldparam t [UniqueType]
      # @yieldreturn [self]
      # @return [self]
      def transform(new_name = nil, &transform_type)
        raise "Please remove leading :: and set rooted with recreate() instead - #{new_name}" if new_name&.start_with?('::')
        if name == ComplexType::GENERIC_TAG_NAME
          # doesn't make sense to manipulate the name of the generic
          new_key_types = @key_types
          new_subtypes = @subtypes
        else
          new_key_types = @key_types.flat_map { |ct| ct.items.map { |ut| ut.transform(&transform_type) } }
          new_subtypes = @subtypes.flat_map { |ct| ct.items.map { |ut| ut.transform(&transform_type) } }
        end
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

      UNDEFINED = UniqueType.new('undefined', rooted: false)
      BOOLEAN = UniqueType.new('Boolean', rooted: true)
    end
  end
end
