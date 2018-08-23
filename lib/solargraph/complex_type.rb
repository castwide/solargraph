module Solargraph
  class ComplexType
    # @return [String]
    attr_reader :name

    # @return [String]
    attr_reader :substring

    # @return [String]
    attr_reader :tag

    # @return [Array<ComplexType>]
    attr_reader :subtypes

    # Create a ComplexType with the specified name and an optional substring.
    # The substring is parameter of a parameterized type, e.g., for the type
    # `Array<String>`, the name is `Array` and the substring is `String`.
    #
    # @param name [String] The name of the type
    # @param substring [String] The substring of the type
    def initialize name, substring = ''
      @name = name
      @substring = substring
      @tag = name + substring
      @key_types = []
      @subtypes = []
      return unless parameters?
      subs = ComplexType.parse(substring[1..-2])
      if hash_parameters?
        raise ComplexTypeError, "Bad hash type" unless subs.length == 2 and subs[0].is_a?(Array) and subs[1].is_a?(Array)
        @key_types.concat subs[0]
        @subtypes.concat subs[1]
      else
        @subtypes.concat subs
      end
    end

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

    def == other
      return false unless self.class == other.class
      tag == other.tag
    end

    class << self
      # @param *strings [Array<String>] The type definitions to parse
      # @return [Array<ComplexType>]
      def parse *strings
        types = []
        key_types = nil
        strings.each do |type_string|
          point_stack = 0
          curly_stack = 0
          paren_stack = 0
          base = ''
          subtype_string = ''
          type_string.each_char do |char|
            if char == '='
              #raise ComplexTypeError, "Invalid = in type #{type_string}" unless curly_stack > 0
            elsif char == '<'
              point_stack += 1
            elsif char == '>'
              if subtype_string.end_with?('=') and curly_stack > 0
                subtype_string += char
              elsif base.end_with?('=')
                raise ComplexTypeError, "Invalid hash thing" unless key_types.nil?
                types.push ComplexType.new(base[0..-2].strip)
                key_types = types
                types = []
                base = ''
                subtype_string = ''
                next
              else
                point_stack -= 1
                subtype_string += char if point_stack == 0
                raise ComplexTypeError, "Invalid close in type #{type_string}" if point_stack < 0
              end
              next
            elsif char == '{'
              curly_stack += 1
            elsif char == '}'
              curly_stack -= 1
              subtype_string += char
              raise ComplexTypeError, "Invalid close in type #{type_string}" if curly_stack < 0
              # types.push ComplexType.parse(subtype_string[1..-2]) if curly_stack == 0
              next
            elsif char == '('
              paren_stack += 1
            elsif char == ')'
              paren_stack -= 1
              subtype_string += char if paren_stack == 0
              raise ComplexTypeError, "Invalid close in type #{type_string}" if paren_stack < 0
              next
            elsif char == ',' and point_stack == 0 and curly_stack == 0 and paren_stack == 0
              types.push ComplexType.new base.strip, subtype_string.strip
              base = ''
              subtype_string = ''
              next
            end
            if point_stack == 0 and curly_stack == 0 and paren_stack == 0
              base += char 
            else
              subtype_string += char
            end
          end
          base.strip!
          subtype_string.strip!
          raise ComplexTypeError, "Unclosed subtype in #{type_string}" if point_stack != 0 or curly_stack != 0 or paren_stack != 0
          types.push ComplexType.new(base, subtype_string)
        end
        unless key_types.nil?
          return key_types if types.empty?
          return [key_types, types]
        end
        types
      end
    end

    VOID = ComplexType.new('void')
  end
end
