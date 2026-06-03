# frozen_string_literal: true

module Solargraph
  module Typedef
    module Linker
      autoload :Base,             'solargraph/typedef/linker/base'
      autoload :Call,             'solargraph/typedef/linker/call'
      autoload :ClassVariable,    'solargraph/typedef/linker/class_variable'
      autoload :Constant,         'solargraph/typedef/linker/constant'
      autoload :InstanceVariable, 'solargraph/typedef/linker/instance_variable'
      autoload :Literal,          'solargraph/typedef/linker/literal'
      autoload :Or,               'solargraph/typedef/linker/or'

      def hitch link, closure
        case link
        when Solargraph::Source::Chain::Head
          return [Pin::ProxyType.anonymous(closure.context, source: :chain)] if link.word == 'self'
          []
        when Solargraph::Source::Chain::Call
          Call.resolve(self, link, closure)
        when Solargraph::Source::Chain::Constant
          Constant.resolve(self, link, closure)
        when Source::Chain::InstanceVariable
          InstanceVariable.resolve(self, link, closure)
        when Source::Chain::Literal
          Literal.resolve(self, link, closure)
        when Source::Chain::Or
          Or.resolve(self, link, closure)
        when Source::Chain::ClassVariable
          ClassVariable.resolve(self, link, closure)
        else
          raise "#{link.class} not implemented"
        end
      end
    end
  end
end
