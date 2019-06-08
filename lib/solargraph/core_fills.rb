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
      Array#select Array#reject Array#keep_if Array#delete_if
      Enumerable#select
      Object#clone Object#dup Object#freeze Object#taint Object#untaint Object#tap
      String#freeze
    ].freeze

    METHODS_RETURNING_SUBTYPES = %w[
      Array#[] Array#first Array#last
    ].freeze

    METHODS_WITH_YIELDPARAM_SELF = %w[
      Object#tap
    ].freeze

    METHODS_WITH_YIELDPARAM_SUBTYPES = %w[
      Array#each Array#map Array#any? Array#all? Array#index Array#keep_if
      Array#delete_if
      Enumerable#each_entry Enumerable#map Enumerable#any? Enumerable#all?
      Enumerable#select Enumerable#reject
      Set#each
    ].freeze

    CUSTOM_RETURN_TYPES = {
      'String#split' => 'Array<String>',
      'String#lines' => 'Array<String>'
    }.freeze
  end
end
