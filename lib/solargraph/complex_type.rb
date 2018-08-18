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
      @subtypes = []
      @subtypes.concat(ComplexType.parse(substring[1..-2])) unless substring.empty?
    end

    # @return [Boolean]
    def duck_type?
      @duck_type ||= name.start_with?('#')
    end

    # @return [Boolean]
    def nil_type?
      @nil_type ||= (name.downcase == 'nil')
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
        strings.each do |type_string|
          point_stack = 0
          curly_stack = 0
          base = ''
          subtype_string = ''
          type_string.each_char do |char|
            if char == '<'
              point_stack += 1
            elsif char == '>'
              point_stack -= 1
              subtype_string += char if point_stack == 0
              raise "Invalid close in type #{type_string}" if point_stack < 0
              next
            elsif char == '{'
              curly_stack += 1
            elsif char == '}'
              curly_stack -= 1
              subtype_string += char if curly_stack == 0
              raise "Invalid close in type #{type_string}" if curly_stack < 0
              next
            elsif char == ',' and point_stack == 0 and curly_stack == 0
              types.push ComplexType.new base.strip, subtype_string.strip
              base = ''
              subtype_string = ''
              next
            end
            if point_stack == 0 and curly_stack == 0
              base += char 
            else
              subtype_string += char
            end
          end
          base.strip!
          subtype_string.strip!
          raise 'Unclosed subtype' if point_stack != 0 or curly_stack != 0
          types.push ComplexType.new(base, subtype_string)
        end
        types
      end
    end
  end
end
