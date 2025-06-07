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
      ].map { |k| Pin::Keyword.new(k, source: :core_fill) }

      MISSING = [
        Solargraph::Pin::Method.new(name: 'class', scope: :instance,
                                    closure: Solargraph::Pin::Namespace.new(name: 'Object', source: :core_fill), comments: '@return [::Class<self>]',
                                    source: :core_fill)
      ]

      OVERRIDES = [
        Override.from_comment('BasicObject#instance_eval', '@yieldreceiver [self]',
                              source: :core_fill),
        Override.from_comment('BasicObject#instance_exec', '@yieldreceiver [self]',
                              source: :core_fill),
        Override.from_comment('Module#define_method', '@yieldreceiver [::Object<self>]',
                              source: :core_fill),
        Override.from_comment('Module#class_eval', '@yieldreceiver [::Class<self>]',
                              source: :core_fill),
        Override.from_comment('Module#class_exec', '@yieldreceiver [::Class<self>]',
                              source: :core_fill),
        Override.from_comment('Module#module_eval', '@yieldreceiver [::Module<self>]',
                              source: :core_fill),
        Override.from_comment('Module#module_exec', '@yieldreceiver [::Module<self>]',
                              source: :core_fill),
        # RBS does not define Class with a generic, so all calls to
        # generic() return an 'untyped'.  We can do better:
        Override.method_return('Class#allocate', 'self', source: :core_fill),
      ]

      # @todo I don't see any direct link in RBS to build this from -
      #   presumably RBS is using duck typing to match interfaces
      #   against concrete classes
      INCLUDES = [
        Solargraph::Pin::Reference::Include.new(name: '_ToAry',
                                                closure: Solargraph::Pin::Namespace.new(name: 'Array', source: :core_fill),
                                                generic_values: ['generic<Elem>'],
                                                source: :core_fill)
      ]

      # HACK: Add Errno exception classes
      errno = Solargraph::Pin::Namespace.new(name: 'Errno', source: :core_fill)
      errnos = []
      Errno.constants.each do |const|
        errnos.push Solargraph::Pin::Namespace.new(type: :class, name: const.to_s, closure: errno, source: :core_fill)
        errnos.push Solargraph::Pin::Reference::Superclass.new(closure: errnos.last, name: 'SystemCallError', source: :core_fill)
      end
      ERRNOS = errnos

      ALL = KEYWORDS + MISSING + OVERRIDES + ERRNOS + INCLUDES
    end
  end
end
