module Solargraph
  module CoreFills
    KEYWORDS = [
      '__ENCODING__', '__LINE__', '__FILE__', 'BEGIN', 'END', 'alias', 'and',
      'begin', 'break', 'case', 'class', 'def', 'defined?', 'do', 'else',
      'elsif', 'end', 'ensure', 'false', 'for', 'if', 'in', 'module', 'next',
      'nil', 'not', 'or', 'redo', 'rescue', 'retry', 'return', 'self', 'super',
      'then', 'true', 'undef', 'unless', 'until', 'when', 'while', 'yield'
    ].freeze

    METHODS_RETURNING_SELF = %w[
      Object#clone Object#dup Object#freeze Object#taint Object#untaint
    ].freeze

    METHODS_RETURNING_SUBTYPES = %w[
      Array#[] Array#first Array#last
    ].freeze

    METHODS_WITH_YIELDPARAM_SUBTYPES = %w[
      Array#each Array#map Array#any? Array#all?
      Enumerable#each_entry Enumerable#map Enumerable#any? Enumerable#all?
      Hash#each_pair
    ].freeze

    CUSTOM_RETURN_TYPES = {
      'String#split' => 'Array<String>'
    }.freeze
  end
end
