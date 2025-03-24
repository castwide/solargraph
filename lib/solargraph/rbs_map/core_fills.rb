# frozen_string_literal: true

module Solargraph
  class RbsMap
    # Override pins to fill gaps in RbsMap::CoreMap coverage
    #
    module CoreFills
      Override = Pin::Reference::Override

      KEYWORDS = [
        '__ENCODING__', '__LINE__', '__FILE__', 'BEGIN', 'END', 'alias', 'and',
        'begin', 'break', 'case', 'class', 'def', 'defined?', 'do', 'else',
        'elsif', 'end', 'ensure', 'false', 'for', 'if', 'in', 'module', 'next',
        'nil', 'not', 'or', 'redo', 'rescue', 'retry', 'return', 'self', 'super',
        'then', 'true', 'undef', 'unless', 'until', 'when', 'while', 'yield'
      ].map { |k| Pin::Keyword.new(k) }

      CLASS_RETURN_TYPES = [
        Override.method_return('Class#new', 'self'),
        Override.method_return('Class.new', 'Class<BasicObject>'),
        Override.method_return('Class#allocate', 'self'),
        Override.method_return('Class.allocate', 'Class<BasicObject>'),
        Override.method_return('Kernel#class', 'Class<self>')
      ]

      ALL = KEYWORDS + CLASS_RETURN_TYPES
    end
  end
end
