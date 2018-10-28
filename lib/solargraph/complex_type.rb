module Solargraph
  # A container for type data based on YARD type tags.
  #
  class ComplexType < Array
    # @todo Figure out how to add the basic type methods here without actually
    #   including the module. One possibility:
    #
    # @!parse
    #   include TypeMethods

    autoload :TypeMethods, 'solargraph/complex_type/type_methods'
    autoload :UniqueType,  'solargraph/complex_type/unique_type'

    # @param types [Array<ComplexType>]
    def initialize types = [ComplexType::UNDEFINED]
      super()
      concat types
    end

    # @param api_map [ApiMap]
    # @param context [String]
    # @return [ComplexType]
    def qualify api_map, context = ''
      types = map do |t|
        t.qualify api_map, context
      end
      ComplexType.new(types)
    end

    def method_missing name, *args, &block
      return if first == nil
      return first.send(name, *args, &block) if respond_to_missing?(name)
      super
    end

    def respond_to_missing?(name, include_private = false)
      TypeMethods.public_instance_methods.include?(name) || super
    end

    def to_s
      map(&:tag).join(', ')
    end

    class << self
      # Parse type strings into a ComplexType.
      #
      # @example
      #   ComplexType.parse 'String', 'Foo', 'nil' #=> [String, Foo, nil]
      #
      # @note
      #   The `partial` parameter is used to indicate that the method is
      #   receiving a string that will be used inside another ComplexType.
      #   It returns arrays of ComplexTypes instead of a single cohesive one.
      #   Consumers should not need to use this parameter; it should only be
      #   used internally.
      #
      # @param *strings [Array<String>] The type definitions to parse
      # @param partial [Boolean] True if the string is part of a another type
      # @return [ComplexType]
      def parse *strings, partial: false
        @cache ||= {}
        unless partial
          cached = @cache[strings]
          return cached unless cached.nil?
        end
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
                types.push ComplexType.new([UniqueType.new(base[0..-2].strip)])
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
              next
            elsif char == '('
              paren_stack += 1
            elsif char == ')'
              paren_stack -= 1
              subtype_string += char if paren_stack == 0
              raise ComplexTypeError, "Invalid close in type #{type_string}" if paren_stack < 0
              next
            elsif char == ',' and point_stack == 0 and curly_stack == 0 and paren_stack == 0
              types.push ComplexType.new([UniqueType.new(base.strip, subtype_string.strip)])
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
          types.push ComplexType.new([UniqueType.new(base, subtype_string)])
        end
        unless key_types.nil?
          raise ComplexTypeError, "Invalid use of key/value parameters" unless partial
          return key_types if types.empty?
          return [key_types, types]
        end
        result = partial ? types : ComplexType.new(types)
        @cache[strings] = result unless partial
        result
      end
    end

    VOID = ComplexType.parse('void')
    UNDEFINED = ComplexType.parse('undefined')
    SYMBOL = ComplexType.parse('Symbol')
    ROOT = ComplexType.parse('Class<>')
  end
end
