# frozen_string_literal: true

module Solargraph
  # A container for type data based on YARD type tags.
  #
  class ComplexType
    GENERIC_TAG_NAME = 'generic'.freeze
    # @!parse
    #   include TypeMethods

    autoload :TypeMethods, 'solargraph/complex_type/type_methods'
    autoload :UniqueType,  'solargraph/complex_type/unique_type'

    # @param types [Array<[UniqueType, ComplexType]>]
    def initialize types = [UniqueType::UNDEFINED]
      # @todo @items here should not need an annotation
      # @type [Array<UniqueType>]
      @items = types.flat_map(&:items).uniq(&:to_s)
    end

    def eql?(other)
      self.class == other.class &&
        @items == other.items
    end

    def ==(other)
      self.eql?(other)
    end

    def hash
      [self.class, @items].hash
    end

    # @param api_map [ApiMap]
    # @param context [String]
    # @return [ComplexType]
    def qualify api_map, context = ''
      red = reduce_object
      types = red.items.map do |t|
        next t if ['nil', 'void', 'undefined'].include?(t.name)
        next t if ['::Boolean'].include?(t.rooted_name)
        t.qualify api_map, context
      end
      ComplexType.new(types).reduce_object
    end

    # @param generics_to_resolve [Enumerable<String>]]
    # @param context_type [UniqueType, nil]
    # @param resolved_generic_values [Hash{String => ComplexType}] Added to as types are encountered or resolved
    # @return [self]
    def resolve_generics_from_context generics_to_resolve, context_type, resolved_generic_values: {}
      return self unless generic?

      ComplexType.new(@items.map { |i| i.resolve_generics_from_context(generics_to_resolve, context_type, resolved_generic_values: resolved_generic_values) })
    end

    # @return [UniqueType]
    def first
      @items.first
    end

    # @return [String]
    def to_rbs
      ((@items.length > 1 ? '(' : '') +
       @items.map(&:to_rbs).join(' | ') +
       (@items.length > 1 ? ')' : ''))
    end

    # @param dst [ComplexType]
    # @return [ComplexType]
    def self_to_type dst
      object_type_dst = dst.reduce_class_type
      transform do |t|
        next t if t.name != 'self'
        object_type_dst
      end
    end

    # @yieldparam [UniqueType]
    # @return [Array]
    def map &block
      @items.map &block
    end

    # @yieldparam [UniqueType]
    # @return [Enumerable<UniqueType>]
    def each &block
      @items.each &block
    end

    # @yieldparam [UniqueType]
    # @return [void]
    # @overload each_unique_type()
    #   @return [Enumerator<UniqueType>]
    def each_unique_type &block
      return enum_for(__method__) unless block_given?

      @items.each do |item|
        item.each_unique_type &block
      end
    end

    # @return [Integer]
    def length
      @items.length
    end

    # @return [Array<UniqueType>]
    def to_a
      @items
    end

    def tags
      @items.map(&:tag).join(', ')
    end

    # @param index [Integer]
    # @return [UniqueType]
    def [](index)
      @items[index]
    end

    # @return [Array<UniqueType>]
    def select &block
      @items.select &block
    end

    # @return [String]
    def namespace
      # cache this attr for high frequency call
      @namespace ||= method_missing(:namespace).to_s
    end

    # @return [Array<String>]
    def namespaces
      @items.map(&:namespace)
    end

    # @param name [Symbol]
    # @return [Object, nil]
    def method_missing name, *args, &block
      return if @items.first.nil?
      return @items.first.send(name, *args, &block) if respond_to_missing?(name)
      super
    end

    # @param name [Symbol]
    # @param include_private [Boolean]
    def respond_to_missing?(name, include_private = false)
      TypeMethods.public_instance_methods.include?(name) || super
    end

    def to_s
      map(&:tag).join(', ')
    end

    def rooted_tags
      map(&:rooted_tag).join(', ')
    end

    def all? &block
      @items.all? &block
    end

    def any? &block
      @items.compact.any? &block
    end

    def selfy?
      @items.any?(&:selfy?)
    end

    def generic?
      any?(&:generic?)
    end

    # @param new_name [String, nil]
    # @yieldparam t [UniqueType]
    # @yieldreturn [UniqueType]
    # @return [ComplexType]
    def transform(new_name = nil, &transform_type)
      raise "Please remove leading :: and set rooted with recreate() instead - #{new_name}" if new_name&.start_with?('::')
      ComplexType.new(map { |ut| ut.transform(new_name, &transform_type) })
    end

    # @return [self]
    def force_rooted
      transform do |t|
        t.recreate(make_rooted: true)
      end
    end

    # @param definitions [Pin::Namespace, Pin::Method]
    # @param context_type [ComplexType]
    # @return [ComplexType]
    def resolve_generics definitions, context_type
      result = @items.map { |i| i.resolve_generics(definitions, context_type) }
      ComplexType.new(result)
    end

    def nullable?
      @items.any?(&:nil_type?)
    end

    # @return [Array<ComplexType>]
    def all_params
      @items.first.all_params || []
    end

    # @return [ComplexType]
    def reduce_class_type
      new_items = items.flat_map do |type|
        next type unless ['Module', 'Class'].include?(type.name)

        type.all_params
      end
      ComplexType.new(new_items)
    end

    attr_reader :items

    protected

    # @return [ComplexType]
    def reduce_object
      new_items = items.flat_map do |ut|
        next [ut] if ut.name != 'Object' || ut.subtypes.empty?
        ut.subtypes
      end
      ComplexType.new(new_items)
    end

    def bottom?
      @items.all?(&:bot?)
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
      # @return [ComplexType]
      # @overload parse(*strings, partial: false)
      #  @todo Need ability to use a literal true as a type below
      #  @param partial [Boolean] True if the string is part of a another type
      #  @return [Array<UniqueType>]
      def parse *strings, partial: false
        # @type [Hash{Array<String> => ComplexType}]
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
          base = String.new
          subtype_string = String.new
          type_string&.each_char do |char|
            if char == '='
              #raise ComplexTypeError, "Invalid = in type #{type_string}" unless curly_stack > 0
            elsif char == '<'
              point_stack += 1
            elsif char == '>'
              if subtype_string.end_with?('=') && curly_stack > 0
                subtype_string += char
              elsif base.end_with?('=')
                raise ComplexTypeError, "Invalid hash thing" unless key_types.nil?
                # types.push ComplexType.new([UniqueType.new(base[0..-2].strip)])
                types.push UniqueType.parse(base[0..-2].strip)
                # @todo this should either expand key_type's type
                #   automatically or complain about not being
                #   compatible with key_type's type in type checking
                key_types = types
                types = []
                base.clear
                subtype_string.clear
                next
              else
                raise ComplexTypeError, "Invalid close in type #{type_string}" if point_stack == 0
                point_stack -= 1
                subtype_string += char
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
              subtype_string += char
              raise ComplexTypeError, "Invalid close in type #{type_string}" if paren_stack < 0
              next
            elsif char == ',' && point_stack == 0 && curly_stack == 0 && paren_stack == 0
              # types.push ComplexType.new([UniqueType.new(base.strip, subtype_string.strip)])
              types.push UniqueType.parse(base.strip, subtype_string.strip)
              base.clear
              subtype_string.clear
              next
            end
            if point_stack == 0 && curly_stack == 0 && paren_stack == 0
              base.concat char
            else
              subtype_string.concat char
            end
          end
          raise ComplexTypeError, "Unclosed subtype in #{type_string}" if point_stack != 0 || curly_stack != 0 || paren_stack != 0
          # types.push ComplexType.new([UniqueType.new(base, subtype_string)])
          types.push UniqueType.parse(base.strip, subtype_string.strip)
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

      # @param strings [Array<String>]
      # @return [ComplexType]
      def try_parse *strings
        parse *strings
      rescue ComplexTypeError => e
        Solargraph.logger.info "Error parsing complex type: #{e.message}"
        ComplexType::UNDEFINED
      end
    end

    VOID = ComplexType.parse('void')
    UNDEFINED = ComplexType.parse('undefined')
    SYMBOL = ComplexType.parse('::Symbol')
    ROOT = ComplexType.parse('::Class<>')
    NIL = ComplexType.parse('nil')
    SELF = ComplexType.parse('self')
    BOOLEAN = ComplexType.parse('::Boolean')
    BOT = ComplexType.parse('bot')
  end
end
