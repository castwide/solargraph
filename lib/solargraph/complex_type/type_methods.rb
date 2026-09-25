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

      # Member pairing shared by ComplexType#combine_via and
      # Intersection#combine_via. ComplexType does not include this
      # mixin, so these are module methods rather than instance ones.
      class << self
        # Pairs two member lists and yields each pair: a lone member
        # on either side takes on the whole of the other; otherwise
        # members both sides carry pair off first and the rest zip up.
        #
        # @param mine [Array<ComplexType, UniqueType>]
        # @param theirs [Array<ComplexType, UniqueType>]
        # @param gather [Proc] gathers several members into one type
        # @yieldparam mine_member [ComplexType, UniqueType]
        # @yieldparam theirs_member [ComplexType, UniqueType]
        # @yieldreturn [ComplexType, UniqueType]
        # @return [Array<ComplexType, UniqueType>] a result per pair, plus anything left unpaired
        def combine_members mine, theirs, gather, &block
          return [block.call(gather.call(mine), gather.call(theirs))] if mine.length == 1 || theirs.length == 1

          mine_rest = mine.dup
          theirs_rest = theirs.dup
          matched = pair_identical_members(mine_rest, theirs_rest, &block)
          zipped = pair_remaining_members(mine_rest, theirs_rest, gather, &block)
          matched + zipped + mine_rest + theirs_rest
        end

        # Yields each member both sides carry, matched on rooted tag
        # and in any order, removing it from both lists.
        #
        # @param mine [Array<ComplexType, UniqueType>] matched members are removed
        # @param theirs [Array<ComplexType, UniqueType>] matched members are removed
        # @yieldparam mine_member [ComplexType, UniqueType]
        # @yieldparam theirs_member [ComplexType, UniqueType]
        # @yieldreturn [ComplexType, UniqueType]
        # @return [Array<ComplexType, UniqueType>]
        def pair_identical_members mine, theirs
          results = []
          mine.delete_if do |member|
            index = theirs.index { |other| other.rooted_tags == member.rooted_tags }
            next false if index.nil?

            results.push(yield(member, theirs.delete_at(index)))
            true
          end
          results
        end

        # Zips both lists from the front, yielding each pair and
        # removing it. The shorter side runs out first, so its last
        # member takes on everything left of the other.
        #
        # @param mine [Array<ComplexType, UniqueType>] paired members are removed
        # @param theirs [Array<ComplexType, UniqueType>] paired members are removed
        # @param gather [Proc] gathers several members into one type
        # @yieldparam mine_member [ComplexType, UniqueType]
        # @yieldparam theirs_member [ComplexType, UniqueType]
        # @yieldreturn [ComplexType, UniqueType]
        # @return [Array<ComplexType, UniqueType>]
        def pair_remaining_members mine, theirs, gather
          results = []
          until mine.empty? || theirs.empty?
            if mine.length == 1 || theirs.length == 1
              results.push(yield(gather.call(mine.dup), gather.call(theirs.dup)))
              mine.clear
              theirs.clear
            else
              results.push(yield(mine.shift, theirs.shift))
            end
          end
          results
        end
      end

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

      # Whether this is an RBS interface like _ToAry or Hash::_Key.
      def interface?
        name.start_with?('_') || name.include?('::_')
      end

      # @return [Boolean]
      def duck_type?
        @duck_type ||= name.start_with?('#')
      end

      # @return [Boolean]
      def nil_type?
        @nil_type ||= name.casecmp('nil').zero?
      end

      def tuple?
        return false
        @tuple ||= (name == 'Tuple') || (name == 'Array' && subtypes.length >= 1 && fixed_parameters?)
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

      # Variance of the type ignoring any type parameters
      # @return [Symbol]
      # @param situation [Symbol] The situation in which the variance is being considered.
      def erased_variance situation = :method_call
        # :nocov:
        unless %i[method_call return_type assignment].include?(situation)
          raise "Unknown situation: #{situation.inspect}"
        end
        # :nocov:
        :covariant
      end

      # @param generics_to_erase [Enumerable<String>]
      # @return [self]
      def erase_generics generics_to_erase
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

      # @type [Hash{String => Symbol}]
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
          %w[Class Module].include?(name) && !subtypes.empty? ? subtypes.first.name : name
        end.call
      end

      # @return [self]
      def namespace_type
        return ComplexType.parse('::Object') if duck_type?
        return ComplexType.parse('::NilClass') if nil_type?
        return subtypes.first if %w[Class Module].include?(name) && !subtypes.empty?
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
      def generate_substring_from &to_str
        key_types_str = key_types.map(&to_str).join(', ')
        subtypes_str = subtypes.map(&to_str).join(', ')
        if (key_types.none?(&:defined?) && subtypes.none?(&:defined?)) ||
           (key_types.empty? && subtypes.empty?)
          ''
        elsif hash_parameters?
          "{#{key_types_str} => #{subtypes_str}}"
        elsif fixed_parameters?
          "(#{subtypes_str})"
        elsif name == 'Hash'
          "<#{key_types_str}, #{subtypes_str}>"
        else
          "<#{key_types_str}#{subtypes_str}>"
        end
      end

      # @return [::Symbol] :class or :instance
      def scope
        @scope ||= :instance if duck_type? || nil_type?
        @scope ||= %w[Class Module].include?(name) && !subtypes.empty? ? :class : :instance
      end

      # @param other [Object]
      def == other
        return false unless self.class == other.class
        # @sg-ignore flow sensitive typing should support .class == .class
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
      # @return [void]
      # @overload each_unique_type()
      #   @return [Enumerator<UniqueType>]
      def each_unique_type &block
        return enum_for(__method__) unless block_given?
        yield self
      end
    end
  end
end
