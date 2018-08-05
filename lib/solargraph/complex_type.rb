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

    def initialize name, substring
      @name = name
      @substring = substring
      @tag = name
      @tag += "<#{substring}>" unless substring.empty?
      @subtypes = []
      @subtypes.concat(ComplexType.parse(substring)) unless substring.empty?
    end

    def duck_type?
      @duck_type ||= name.start_with?('#')
    end

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

    class << self
      # @return [Array<ComplexType>]
      def parse *strings
        types = []
        strings.each do |type_string|
          point_stack = 0
          base = ''
          subtype_string = ''
          type_string.each_char do |char|
            if char == '<'
              point_stack += 1
              next if point_stack == 1
            elsif char == '>'
              point_stack -= 1
              raise 'Invalid close in type' if point_stack < 0
            elsif char == ',' and point_stack == 0
              types.push ComplexType.new base.strip, subtype_string.strip
              base = ''
              subtype_string = ''
              next
            end
            if point_stack == 0 and char != '>'
              base += char 
            elsif point_stack != 0
              subtype_string += char
            end
          end
          base.strip!
          subtype_string.strip!
          raise 'Unclosed subtype' if point_stack != 0
          types.push ComplexType.new base, subtype_string
        end
        types
      end
    end
  end
end
