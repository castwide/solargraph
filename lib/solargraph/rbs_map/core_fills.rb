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

      MISSING = [
        Solargraph::Pin::Method.new(name: 'tap', scope: :instance,
                                    closure: Solargraph::Pin::Namespace.new(name: 'Object')),
        Solargraph::Pin::Method.new(name: 'class', scope: :instance,
                                    closure: Solargraph::Pin::Namespace.new(name: 'Object'), comments: '@return [Class<self>]')
      ]

      CLASS_RETURN_TYPES = [
        Override.method_return('Class#new', 'self'),
        Override.method_return('Class.new', 'Class<BasicObject>'),
        Override.method_return('Class#allocate', 'self'),
        Override.method_return('Class.allocate', 'Class<BasicObject>')
      ]

      ALL = KEYWORDS + MISSING + CLASS_RETURN_TYPES
    end
  end
end
