module Solargraph
  class ComplexType < Array
    # @todo Figure out how to add the basic type methods here without actually
    #   including the module. One possibility:
    #
    # @!parse
    #   include BasicTypeMethods

    def initialize types = [ComplexType::UNDEFINED]
      super()
      concat types
    end

    def method_missing name, *args, &block
      return first.send(name, *args, &block) if BasicTypeMethods.public_instance_methods.include?(name)
      super
    end

    def respond_to_missing?(name, include_private = false)
      BasicTypeMethods.public_instance_methods.include?(name) || super
    end

    class << self
      # @param *strings [Array<String>] The type definitions to parse
      # @return [ComplexType]
      def parse *strings, raw: false
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
                types.push ComplexType.new([BasicType.new(base[0..-2].strip)])
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
              types.push ComplexType.new([BasicType.new(base.strip, subtype_string.strip)])
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
          types.push ComplexType.new([BasicType.new(base, subtype_string)])
        end
        unless key_types.nil?
          raise ComplexTypeError, "Invalid use of key/value parameters" unless raw
          return key_types if types.empty?
          return [key_types, types]
        end
        raw ? types : ComplexType.new(types)
      end
    end

    VOID = ComplexType.parse('void')
    UNDEFINED = ComplexType.parse('undefined')
  end
end
