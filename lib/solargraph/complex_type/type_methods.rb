# frozen_string_literal: true

module Solargraph
  class ComplexType
    # Methods for accessing type data available from
    # both ComplexType and UniqueType.
    #
    # @abstract This mixin relies on these -
    #   instance variables:
    #     @name: String
    #     @subtypes: Array<ComplexType>
    #     @rooted: boolish
    #   methods:
    #     transform()
    #     all_params()
    #     rooted?()
    #     can_root_name?()
    module TypeMethods
      # @!method transform(new_name = nil, &transform_type)
      #   @param new_name [String, nil]
      #   @yieldparam t [UniqueType]
      #   @yieldreturn [UniqueType]
      #   @return [UniqueType, nil]
      # @!method all_params
      #   @return [Array<ComplexType>]
      # @!method rooted?
      # @!method can_root_name?(name_to_check = nil)
      #   @param name_to_check [String, nil]

      # @return [String]
      attr_reader :name

      # @return [Array<ComplexType>]
      attr_reader :subtypes

      # @return [String]
      def tag
        @tag ||= "#{name}#{substring}"
      end

      # @return [String]
      def rooted_tag
        @rooted_tag ||= rooted_name + rooted_substring
      end

      # @return [Boolean]
      def duck_type?
        @duck_type ||= name.start_with?('#')
      end

      # @return [Boolean]
      def nil_type?
        @nil_type ||= (name.casecmp('nil') == 0)
      end

      def tuple?
        @tuple_type ||= (name == 'Tuple') || (name == 'Array' && subtypes.length >= 1 && fixed_parameters?)
      end

      def void?
        name == 'void'
      end

      def defined?
        !undefined?
      end

      def undefined?
        name == 'undefined'
      end

      # @param generics_to_erase [Enumerable<String>]
      # @return [self]
      def erase_generics(generics_to_erase)
        transform do |type|
          if type.name == ComplexType::GENERIC_TAG_NAME
            if type.all_params.length == 1 && generics_to_erase.include?(type.all_params.first.to_s)
              ComplexType::UNDEFINED
            else
              type
            end
          else
            type
          end
        end
      end

      # @return [Symbol, nil]
      attr_reader :parameters_type

      PARAMETERS_TYPE_BY_STARTING_TAG = {
        '{' => :hash,
        '(' => :fixed,
        '<' => :list
      }.freeze

      # @return [Boolean]
      def list_parameters?
        parameters_type == :list
      end

      # @return [Boolean]
      def fixed_parameters?
        parameters_type == :fixed
      end

      # @return [Boolean]
      def hash_parameters?
        parameters_type == :hash
      end

      # @return [Array<ComplexType>]
      def value_types
        @subtypes
      end

      # @return [Array<ComplexType>]
      def key_types
        @key_types
      end

      # @return [String]
      def namespace
        # if priority higher than ||=, old implements cause unnecessary check
        @namespace ||= lambda do
          return 'Object' if duck_type?
          return 'NilClass' if nil_type?
          return (name == 'Class' || name == 'Module') && !subtypes.empty? ? subtypes.first.name : name
        end.call
      end

      def namespace_type
        return ComplexType.parse('::Object') if duck_type?
        return ComplexType.parse('::NilClass') if nil_type?
        return subtypes.first if (name == 'Class' || name == 'Module') && !subtypes.empty?
        self
      end

      # @return [String]
      def rooted_namespace
        return namespace unless rooted? && can_root_name?(namespace)
        "::#{namespace}"
      end

      # @return [String]
      def rooted_name
        return name unless @rooted && can_root_name?
        "::#{name}"
      end

      # @return [String]
      def substring
        @substring ||= generate_substring_from(&:tags)
      end

      # @return [String]
      def rooted_substring
        @rooted_substring = generate_substring_from(&:rooted_tags)
      end

      # @return [String]
      def generate_substring_from(&to_str)
        key_types_str = key_types.map(&to_str).join(', ')
        subtypes_str = subtypes.map(&to_str).join(', ')
        if key_types.none?(&:defined?) && subtypes.none?(&:defined?)
          ''
        elsif key_types.empty? && subtypes.empty?
          ''
        elsif hash_parameters?
          "{#{key_types_str} => #{subtypes_str}}"
        elsif fixed_parameters?
          "(#{subtypes_str})"
        else
          "<#{subtypes_str}>"
        end
      end

      # @return [::Symbol] :class or :instance
      def scope
        @scope ||= :instance if duck_type? || nil_type?
        @scope ||= (name == 'Class' || name == 'Module') && !subtypes.empty? ? :class : :instance
      end

      # @param other [Object]
      def == other
        return false unless self.class == other.class
        tag == other.tag
      end

      # Generate a ComplexType that fully qualifies this type's namespaces.
      #
      # @param api_map [ApiMap] The ApiMap that performs qualification
      # @param context [String] The namespace from which to resolve names
      # @return [self, ComplexType, UniqueType] The generated ComplexType
      def qualify api_map, context = ''
        transform do |t|
          next t if t.name == GENERIC_TAG_NAME
          next t if t.duck_type? || t.void? || t.undefined?
          recon = (t.rooted? ? '' : context)
          fqns = api_map.qualify(t.name, recon)
          if fqns.nil?
            next UniqueType::BOOLEAN if t.tag == 'Boolean'
            next UniqueType::UNDEFINED
          end
          t.recreate(new_name: fqns, make_rooted: true)
        end
      end

      # @yieldparam [UniqueType]
      # @return [Enumerator<UniqueType>]
      def each_unique_type &block
        return enum_for(__method__) unless block_given?
        yield self
      end
    end
  end
end
