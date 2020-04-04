# frozen_string_literal: true

module Solargraph
  # Overrides for the Ruby core.
  #
  # The YardMap uses this module to add type information to core methods.
  #
  module CoreFills
    Override = Pin::Reference::Override

    KEYWORDS = [
      '__ENCODING__', '__LINE__', '__FILE__', 'BEGIN', 'END', 'alias', 'and',
      'begin', 'break', 'case', 'class', 'def', 'defined?', 'do', 'else',
      'elsif', 'end', 'ensure', 'false', 'for', 'if', 'in', 'module', 'next',
      'nil', 'not', 'or', 'redo', 'rescue', 'retry', 'return', 'self', 'super',
      'then', 'true', 'undef', 'unless', 'until', 'when', 'while', 'yield'
    ].freeze

    methods_with_yieldparam_subtypes = %w[
      Array#each Array#map Array#map! Array#any? Array#all? Array#index
      Array#keep_if Array#delete_if
      Enumerable#each_entry Enumerable#map Enumerable#any? Enumerable#all?
      Enumerable#select Enumerable#reject
      Set#each
    ]

    OVERRIDES = [
      Override.method_return('Array#keep_if', 'self'),
      Override.method_return('Array#delete_if', 'self'),
      Override.from_comment('Array#reject', %(
@overload reject(&block)
  @return [self]
@overload reject()
  @return [Enumerator]
              )),
      Override.method_return('Array#reverse', 'self', delete: ['overload']),
      Override.from_comment('Array#select', %(
@overload select(&block)
  @return [self]
@overload select()
  @return [Enumerator]
      )),
      Override.from_comment('Array#[]', %(
@overload [](range)
  @param range [Range]
  @return [self]
@overload [](num1, num2)
  @param num1 [Integer]
  @param num2 [Integer]
  @return [self]
@overload [](num)
  @param num [Integer]
  @return_single_parameter
@return_single_parameter
      )),
      Override.from_comment('Array#first', %(
@overload first(num)
  @param num [Integer]
  @return [self]
@return_single_parameter
      )),
      Override.from_comment('Array#last', %(
@overload last(num)
  @param num [Integer]
  @return [self]
@return_single_parameter
      )),

      Override.from_comment('BasicObject#==', %(
@param other [BasicObject]
@return [Boolean]
      )),
      Override.method_return('BasicObject#initialize', 'void'),

      Override.method_return('Class#new', 'self'),
      Override.method_return('Class.new', 'Class<Object>'),
      Override.method_return('Class#allocate', 'self'),
      Override.method_return('Class.allocate', 'Class<Object>'),

      Override.method_return('Enumerable#select', 'self'),

      Override.method_return('File.absolute_path', 'String'),
      Override.method_return('File.basename', 'String'),
      Override.method_return('File.dirname', 'String'),
      Override.method_return('File.extname', 'String'),
      Override.method_return('File.join', 'String'),

      Override.from_comment('Hash#[]', %(
@return_value_parameter
      )),

      # @todo This override isn't robust enough. It needs to allow for
      #   parameterized Hash types, e.g., [Hash{Symbol => String}].
      Override.from_comment('Hash#[]=', %(
@param_tuple
      )),

      Override.from_comment('Integer#+', %(
@param num [Numeric]
@return [Numeric]
      )),

      # Override.method_return('Module#attr_reader', 'void'),
      # Override.method_return('Module#attr_writer', 'void'),
      # Override.method_return('Module#attr_accessor', 'void'),

      Override.from_comment('Numeric#+', %(
@param num [Numeric]
@return [Numeric]
      )),

      Override.method_return('Object#!', 'Boolean'),
      Override.method_return('Object#clone', 'self', delete: [:overload]),
      Override.method_return('Object#dup', 'self', delete: [:overload]),
      Override.method_return('Object#freeze', 'self', delete: [:overload]),
      Override.method_return('Object#inspect', 'String'),
      Override.method_return('Object#taint', 'self'),
      Override.method_return('Object#to_s', 'String'),
      Override.method_return('Object#untaint', 'self'),
      Override.from_comment('Object#tap', %(
@return [self]
@yieldparam [self]
      )),

      Override.from_comment('STDERR', %(
@type [IO]
      )),

      Override.from_comment('STDIN', %(
@type [IO]
      )),

      Override.from_comment('STDOUT', %(
@type [IO]
      )),

      Override.method_return('String#freeze', 'self'),
      Override.method_return('String#split', 'Array<String>'),
      Override.method_return('String#lines', 'Array<String>'),
      Override.from_comment('String#each_line', %(
@yieldparam [String]
      ))
    ].concat(
      methods_with_yieldparam_subtypes.map do |path|
        Override.from_comment(path, %(
@yieldparam_single_parameter
          ))
      end
    )
  end
end
