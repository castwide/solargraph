module Solargraph
  module BasicTypeMethods
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
      @nil_type ||= (name.downcase == 'nil')
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
      @namespace ||= 'Object' if duck_type?
      @namespace ||= 'NilClass' if nil_type?
      @namespace ||= ((name == 'Class' or name == 'Module') and !subtypes.empty?) ? subtypes.first.name : name
    end

    # @return [Symbol] :class or :instance
    def scope
      @scope ||= :instance if duck_type? or nil_type?
      @scope ||= ((name == 'Class' or name == 'Module') and !subtypes.empty?) ? :class : :instance
    end

    # @todo Candidate for deprecation. Complex types already have all the
    #   information a context needs, plus extra stuff that's needed in
    #   Chain::Call.
    # def context
    #   @context ||= Context.new(namespace, scope)
    # end

    def == other
      return false unless self.class == other.class
      tag == other.tag
    end

    # Generate a ComplexType that fully qualifies this type's namespaces.
    #
    # @param api_map [ApiMap] The ApiMap that performs qualification
    # @param context [String] The namespace from which to resolve names
    # @return [ComplexType] The generated ComplexType
    def qualify api_map, context = ''
      return ComplexType.parse(tag) if duck_type? or void? or undefined?
      fqns = api_map.qualify(name, context)
      return ComplexType::UNDEFINED if fqns.nil?
      ltypes = key_types.map do |t|
        t.qualify api_map, context
      end
      rtypes = value_types.map do |t|
        t.qualify api_map, context
      end
      if list_parameters?
        Solargraph::ComplexType.parse("#{fqns}<#{rtypes.map(&:tag).join(', ')}>").first
      elsif fixed_parameters?
        Solargraph::ComplexType.parse("#{fqns}(#{rtypes.map(&:tag).join(', ')})").first
      elsif hash_parameters?
        Solargraph::ComplexType.parse("#{fqns}{#{ltypes.map(&:tag).join(', ')} => #{rtypes.map(&:tag).join(', ')}}").first
      else
        Solargraph::ComplexType.parse(fqns).first
      end
    end
  end
end
