module Solargraph
  module CoreFills
    KEYWORDS = [
      '__ENCODING__', '__LINE__', '__FILE__', 'BEGIN', 'END', 'alias', 'and',
      'begin', 'break', 'case', 'class', 'def', 'defined?', 'do', 'else',
      'elsif', 'end', 'ensure', 'false', 'for', 'if', 'in', 'module', 'next',
      'nil', 'not', 'or', 'redo', 'rescue', 'retry', 'return', 'self', 'super',
      'then', 'true', 'undef', 'unless', 'until', 'when', 'while', 'yield'
    ].freeze

    METHODS_RETURNING_SUBTYPES = %w[
      Array#[] Array#first Array#last
    ].freeze

    METHODS_RETURNING_VALUE_TYPES = %w[
      Hash#[]
    ].freeze

    METHODS_WITH_YIELDPARAM_SUBTYPES = %w[
      Array#each Array#map Array#any? Array#all? Array#index Array#keep_if
      Array#delete_if
      Enumerable#each_entry Enumerable#map Enumerable#any? Enumerable#all?
      Enumerable#select Enumerable#reject
      Set#each
    ].freeze

    class << self
      private

      def override path, *tags
        Solargraph::Pin::Reference::Override.new(nil, path, [YARD::Tags::Tag.new('return', nil, tags)])
      end
    end

    OVERRIDES = [
      override('Array#select', 'self'),
      override('Array#reject', 'self'),
      override('Array#keep_if', 'self'),
      override('Array#delete_if', 'self'),
      Pin::Reference::Override.from_comment('Array#[]', %(
@overload [](rng)
  @param rng [Range]
  @return [self]
@overload [](num1, num2)
  @param num1 [Integer]
  @param num2 [Integer]
  @return [self]
      )),

      override('Class#new', 'self'),
      override('Class.new', 'Class<Object>'),
      override('Class#allocate', 'self'),
      override('Class.allocate', 'Class<Object>'),

      override('Enumerable#select', 'self'),

      override('File.dirname', 'String'),

      override('Object#!', 'Boolean'),
      override('Object#clone', 'self'),
      override('Object#dup', 'self'),
      override('Object#freeze', 'self'),
      override('Object#taint', 'self'),
      override('Object#untaint', 'self'),
      Pin::Reference::Override.from_comment('Object#tap', %(
@return [self]
@yieldparam [self]
      )),

      override('String#freeze', 'self'),
      override('String#split', 'Array<String>'),
      override('String#lines', 'Array<String>')
    ]
  end
end
