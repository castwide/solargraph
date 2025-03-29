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

      OVERRIDES = [
        Override.from_comment('BasicObject#instance_eval', '@yieldreceiver [self]'),
        Override.from_comment('BasicObject#instance_exec', '@yieldreceiver [self]'),
        Override.from_comment('Module#define_method', '@yieldreceiver [Object<self>]'),
        Override.from_comment('Module#class_eval', '@yieldreceiver [Class<self>]'),
        Override.from_comment('Module#class_exec', '@yieldreceiver [Class<self>]'),
        Override.from_comment('Module#module_eval', '@yieldreceiver [Module<self>]'),
        Override.from_comment('Module#module_exec', '@yieldreceiver [Module<self>]')
      ]

      # HACK: Add Errno exception classes
      errno = Solargraph::Pin::Namespace.new(name: 'Errno')
      errnos = []
      Errno.constants.each do |const|
        errnos.push Solargraph::Pin::Namespace.new(type: :class, name: const.to_s, closure: errno)
        errnos.push Solargraph::Pin::Reference::Superclass.new(closure: errnos.last, name: 'SystemCallError')
      end
      ERRNOS = errnos

      ALL = KEYWORDS + MISSING + OVERRIDES + ERRNOS
    end
  end
end
