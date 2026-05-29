# frozen_string_literal: true

module Solargraph
  module Typedef
    module Linker
      autoload :Base,          'solargraph/typedef/linker/base'
      autoload :Call,          'solargraph/typedef/linker/call'
      autoload :ClassVariable, 'solargraph/typedef/linker/class_variable'
      autoload :Constant,      'solargraph/typedef/linker/constant'
      autoload :Or,            'solargraph/typedef/linker/or'

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
          ivars = api_map.get_instance_variable_pins(closure.context.namespace, closure.context.scope).select do |p|
            p.name == link.word
          end
          out = api_map.var_at_location(ivars, link.word, closure, location)
          [out].compact
        when Source::Chain::Literal
          type_name = link.word.sub(/^</, '').sub(/>$/, '')
          complex_type = ComplexType.parse(type_name)
          [Pin::ProxyType.anonymous(complex_type, source: :chain)]
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
