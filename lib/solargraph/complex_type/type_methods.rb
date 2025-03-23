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
    module TypeMethods
      # @!method transform(new_name = nil, &transform_type)
      #   @param new_name [String, nil]
      #   @yieldparam t [UniqueType]
      #   @yieldreturn [UniqueType]
      #   @return [UniqueType, nil]

      # @return [String]
      attr_reader :name

      # @return [String]
      attr_reader :substring

      # @return [String]
      attr_reader :tag

      # @return [Array<ComplexType>]
      attr_reader :subtypes

      # @return [Boolean]
      def duck_type?
        @duck_type ||= name.start_with?('#')
      end

      # @return [Boolean]
      def nil_type?
        @nil_type ||= (name.casecmp('nil') == 0)
      end

      # @return [Boolean]
      def parameters?
        !substring.empty?
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

      # @return [Boolean]
      def list_parameters?
        substring.start_with?('<')
      end

      # @return [Boolean]
      def fixed_parameters?
        substring.start_with?('(')
      end

      # @return [Boolean]
      def hash_parameters?
        substring.start_with?('{')
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

      # @return [String]
      def rooted_namespace
        return namespace unless rooted?
        "::#{namespace}"
      end

      # @return [String]
      def rooted_name
        return name unless rooted?
        "::#{name}"
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

      def rooted?
        @rooted
      end

      # Generate a ComplexType that fully qualifies this type's namespaces.
      #
      # @param api_map [ApiMap] The ApiMap that performs qualification
      # @param context [String] The namespace from which to resolve names
      # @return [self, ComplexType, UniqueType] The generated ComplexType
      def qualify api_map, context = ''
        return self if name == GENERIC_TAG_NAME
        return ComplexType.new([self]) if duck_type? || void? || undefined?
        recon = (rooted? ? '' : context)
        fqns = api_map.qualify(name, recon)
        if fqns.nil?
          return UniqueType::BOOLEAN if tag == 'Boolean'
          return UniqueType::UNDEFINED
        end
        fqns = "::#{fqns}" # Ensure the resulting complex type is rooted
        all_ltypes = key_types.map { |t| t.qualify api_map, context }.uniq
        all_rtypes = value_types.map { |t| t.qualify api_map, context }
        if list_parameters?
          rtypes = all_rtypes.uniq
          Solargraph::ComplexType.parse("#{fqns}<#{rtypes.map(&:tag).join(', ')}>")
        elsif fixed_parameters?
          Solargraph::ComplexType.parse("#{fqns}(#{all_rtypes.map(&:tag).join(', ')})")
        elsif hash_parameters?
          ltypes = all_ltypes.uniq
          rtypes = all_rtypes.uniq
          Solargraph::ComplexType.parse("#{fqns}{#{ltypes.map(&:tag).join(', ')} => #{rtypes.map(&:tag).join(', ')}}")
        else
          Solargraph::ComplexType.parse(fqns)
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
