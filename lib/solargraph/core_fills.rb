module Solargraph
  module CoreFills
    KEYWORDS = [
      '__ENCODING__', '__LINE__', '__FILE__', 'BEGIN', 'END', 'alias', 'and',
      'begin', 'break', 'case', 'class', 'def', 'defined?', 'do', 'else',
      'elsif', 'end', 'ensure', 'false', 'for', 'if', 'in', 'module', 'next',
      'nil', 'not', 'or', 'redo', 'rescue', 'retry', 'return', 'self', 'super',
      'then', 'true', 'undef', 'unless', 'until', 'when', 'while', 'yield'
    ].freeze

    METHODS_RETURNING_SELF = %w{
      clone dup freeze taint untaint
    }.freeze

    METHODS_RETURNING_SUBTYPES = %w{
      Array#[]
    }.freeze

    METHODS_WITH_YIELDPARAM_SUBTYPES = %w{
      Array#each Hash#each_pair Array#map
    }.freeze
  end
end
