# frozen_string_literal: true

module Solargraph
  module Typedef
    module Linker
      autoload :Base, 'solargraph/typedef/linker/base'
      autoload :Call, 'solargraph/typedef/linker/call'
      autoload :Or, 'solargraph/typedef/linker/or'

      def hitch link, closure
        case link
        when Solargraph::Source::Chain::Head
          return [Pin::ProxyType.anonymous(closure.binder, source: :chain)] if link.word == 'self'
          []
        when Solargraph::Source::Chain::Call
          Call.resolve(self, link, closure)
        when Solargraph::Source::Chain::Constant
          return [Pin::ROOT_PIN] if link.word.empty?
          if link.word.start_with?('::')
            base = link.word[2..]
            gates = ['']
          else
            base = link.word
            gates = closure.gates
          end
          # @sg-ignore Need to add nil check here
          fqns = api_map.resolve(base, gates)
          # @sg-ignore Need to add nil check here
          api_map.get_path_pins(fqns)
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
        else
          raise "#{link.class} not implemented"
        end
      end
    end
  end
end
